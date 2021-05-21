class AddressSerializer < FastJSONAPISerializer::Base(Address)
  attributes :street
end

class AddressWithTypeSerializer < FastJSONAPISerializer::Base(Address)
  attributes :street

  type "my_address"
end

class AddressWithUUIDSerializer < FastJSONAPISerializer::Base(AddressWithUUID)
  attributes :street
end

class AddressWithStringSerializer < FastJSONAPISerializer::Base(AddressWithString)
  attributes :street
end

class AddressWithMetaSerializer < FastJSONAPISerializer::Base(Address)
  attributes :street

  def self.meta(*options)
    {:page => 0}
  end
end

class PostCodeSerializer < FastJSONAPISerializer::Base(PostCode)
  attributes :code
end

class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name
  attribute :rating, :Rating, if: :test_rating
  attribute :own_field

  belongs_to :address, AddressSerializer

  has_one :post_code, PostCodeSerializer

  has_many :rooms, RoomSerializer
  has_many :tables, TableSerializer, :Tables
  has_many :guests, GuestSerializer
  has_many :diners, GuestSerializer
  has_many :vips, VIPSerializer

  def test_rating(object, options)
    options.nil? || !options[:test]?
  end

  def own_field
    12
  end
end

class RoomSerializer < FastJSONAPISerializer::Base(Room)
  attribute :name

  has_many :tables, TableSerializer
end

class TableSerializer < FastJSONAPISerializer::Base(Table)
  attribute :number

  belongs_to :room, RoomSerializer
end

class GuestSerializer < FastJSONAPISerializer::Base(Guest)
  attributes :age, :name

  type "guest"

  has_many :friends, GuestSerializer
end

class VIPSerializer < FastJSONAPISerializer::Base(Guest)
  attributes :age, :name

  type "guest"
end

class InheritedSerializer < RestaurantSerializer
  attribute :inherited_field

  has_many :more_guests, GuestSerializer

  def inherited_field
    1.23
  end
end

# edge conditions

class RestaurantWithoutIdSerializer < FastJSONAPISerializer::Base(RestaurantWithoutId)
  attribute :name
end
