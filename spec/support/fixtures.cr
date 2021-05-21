class Address
  getter id
  property street

  def initialize(@id = 101, @street = "some street")
  end
end

class AddressWithUUID
  getter id
  property street

  def initialize(@id : UUID, @street = "some street")
  end
end

class AddressWithString
  getter id
  property street

  def initialize(@id : String, @street = "some street")
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
    guests : Array(Guest) = [] of Guest,
    rooms : Array(Room) = [] of Room

  def initialize(@name = "big burgers")
  end

  def rating
    "Great!"
  end

  def id
    1
  end

  def more_guests
    [Guest.new(123)]
  end

  def diners
    [Guest.new(60)]
  end

  def vips
    [Guest.new(1)]
  end

  def tables
    [Table.new(1), Table.new(2), Table.new(3)]
  end
end

class Room
  property id : Int32 = 1,
    tables : Array(Table) = [] of Table

  def initialize(@id)
  end

  def name
    "#{id}-name"
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

class Guest
  property age,
    id : Int32 = Random.rand(5)

  def initialize(@id, @age = 25)
  end

  def name
    "Joe"
  end

  def friends
    [Guest.new(1), Guest.new(2), Guest.new(3)]
  end
end

# edge conditions

class RestaurantWithoutId
  property name

  def initialize(@name = "big burgers")
  end
end
