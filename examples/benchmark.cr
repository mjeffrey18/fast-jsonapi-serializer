# crystal run --release examples/benchmark.cr

require "benchmark"
require "../src/fast-jsonapi-serializer"
require "jsonapi-serializer-cr"

class Address
  getter id
  property street

  def initialize(@id = 101, @street = "some street")
  end
end

class PostCode
  getter id
  property code

  def initialize(@id = 101, @code = "code 24")
  end
end

class Restaurant
  property name,
    address : Nil | Address = nil,
    post_code : Nil | PostCode = nil,
    rooms : Array(Room) = [] of Room,
    tables : Array(Table) = [Table.new(1), Table.new(2), Table.new(3)]

  def initialize(@name = "big burgers")
  end

  def rating
    "Great!"
  end

  def id
    1
  end
end

class Room
  property id : Int32 = 1,
    tables : Array(Table) = [] of Table,
    name : String = "Name"

  def initialize(@id)
  end
end

class Table
  property number

  def initialize(@number = 1)
  end

  def room
    Room.new(number)
  end

  def id
    number
  end
end

# fast-jsonapi-serializer

class AddressSerializer < FastJSONAPISerializer::Base(Address)
  attributes :street
  type "address" # be specific about the JSON-API type - default to Model camelcase
end

class PostCodeSerializer < FastJSONAPISerializer::Base(PostCode)
  attributes :code
end

class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name
  attribute :rating, :Rating, if: :test_rating
  attribute :own_field

  belongs_to :address, serializer: AddressSerializer # option key-word args

  has_one :post_code, PostCodeSerializer

  has_many :rooms, RoomSerializer
  has_many :tables, TableSerializer, :Tables

  def test_rating(object, options)
    options.nil? || !options[:test]?
  end

  def own_field
    12
  end

  # default meta
  def self.meta(*options)
    {:page => 0}
  end
end

class SingleRestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name
end

class RoomSerializer < FastJSONAPISerializer::Base(Room)
  attribute :name

  has_many :tables, TableSerializer
end

class TableSerializer < FastJSONAPISerializer::Base(Table)
  attribute :number

  belongs_to :room, RoomSerializer
end

# jsonapi-serializer

class AddressSerializerB < JSONApiSerializer::ResourceSerializer(Address)
  identifier id
  type "address"
  attribute street
end

class PostCodeSerializerB < JSONApiSerializer::ResourceSerializer(PostCode)
  identifier id
  type "post_code"
  attribute code
end

class RestaurantSerializerB < JSONApiSerializer::ResourceSerializer(Restaurant)
  identifier id
  type "restaurant"
  attribute name

  relationship(address) { @address_serializer }
  relationship_id address, "address", "address"

  relationship(post_code) { @post_code_serializer }
  relationship_id post_code, "post_code", "post_code"

  relationship(rooms) { RoomSerializerB.new }
  relationship_id rooms, "rooms", "rooms"

  relationship(tables) { TableSerializerB.new }
  relationship_id tables, "tables", "tables"

  def initialize(@address_serializer : AddressSerializerB, @post_code_serializer : PostCodeSerializerB)
    super(nil)
  end
end

class SingleRestaurantSerializerB < JSONApiSerializer::ResourceSerializer(Restaurant)
  identifier id
  type "restaurant"
  attribute name
end

class RoomSerializerB < JSONApiSerializer::ResourceSerializer(Room)
  identifier id
  type "room"
  attribute name

  relationship(tables) { TableSerializerB.new }
  relationship_id tables, "tables", "tables"
end

class TableSerializerB < JSONApiSerializer::ResourceSerializer(Table)
  identifier id
  type "table"
  attribute number

  relationship(room) { RoomSerializerB.new }
  relationship_id room, "room", "room"
end

resource = Restaurant.new

full_resource = Restaurant.new
full_resource.address = Address.new
full_resource.post_code = PostCode.new
room = Room.new(1)
room.tables = [Table.new(1), Table.new(2)]
full_resource.rooms = [room]

serialize_args = {
  except:   %i(name),
  includes: {
    :address   => [:address],
    :post_code => [:post_code],
    :tables    => {:room => [:room]},
  },
  meta:    {:page => 0, :limit => 50},
  options: {:test => true},
}

puts "With various relationships and all API features used"
puts

Benchmark.ips do |x|
  x.report("FastJSONAPISerializer") { RestaurantSerializer.new(full_resource).serialize(**serialize_args) }
  x.report("JSONApiSerializer") { RestaurantSerializerB.new(AddressSerializerB.new, PostCodeSerializerB.new).serialize(full_resource) }
end

puts
puts "Single object with 1 attribute"
puts

Benchmark.ips do |x|
  x.report("FastJSONAPISerializer") { SingleRestaurantSerializer.new(resource).serialize }
  x.report("JSONApiSerializer") { SingleRestaurantSerializerB.new.serialize(resource) }
end
