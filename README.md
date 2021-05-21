# FastJSONAPISerializer

![Build Status](https://github.com/mjeffrey18/fast-jsonapi-serializer-cr/actions/workflows/ci/badge.svg?branch=main) [![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://mjeffrey18.github.io/fast-jsonapi-serializer-cr/) [![GitHub release](https://img.shields.io/github/release/mjeffrey18/fast-jsonapi-serializer-cr.svg)](https://github.com/mjeffrey18/fast-jsonapi-serializer-cr/releases)


Fast JSON-API Serializer is a fast, flexible and simple [JSON-API](https://jsonapi.org) serializer for crystal.

Refer to the full API [documentation](https://mjeffrey18.github.io/fast-jsonapi-serializer-cr/)

## Why use it? 😅

- Works with any ORM or plain Crystal objects.
- Offers a very flexible API.
- Did I mention it was fast?

## Benchmarks 🚀

> **Spoiler** **~200%** faster!

*Compared to other JSON-API compliant alternatives. Sure, benchmarks are to be taken with a grain of salt...*

See `examples/benchmark.cr` for the full benchmark setup.

(Kitchen Sink) With various relationships and all API features used -

```
FastJSONAPISerializer  66.54k ( 15.03µs) (± 2.25%)  22.2kB/op        fastest
    JSONApiSerializer  34.32k ( 29.14µs) (± 2.49%)  33.0kB/op   1.94× slower
```

Single object with 1 attribute

```
FastJSONAPISerializer 881.46k (  1.13µs) (± 1.98%)  1.47kB/op        fastest
    JSONApiSerializer 669.06k (  1.49µs) (± 2.65%)  1.44kB/op   1.32× slower
```

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  fast-jsonapi-serializer-cr:
    github: mjeffrey18/fast-jsonapi-serializer-cr
```

2. Run `shards install`

## Setup

Require the shard in your project.

```crystal
require "fast-jsonapi-serializer-cr"
```

## Usage

### Quick Introduction

Considering a model/resource (ORM or plain crystal class)

```crystal
class Restaurant
  property name

  def initialize(@name = "big burgers")
  end
end
```

Create a serializer which inherits from `FastJSONAPISerializer::Base(YourResourceClass)`

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name
end
```

Use the `serialize` API to to build a `JSON-API` compatible string

#### Single Resource

```crystal
resource = Restaurant.new
RestaurantSerializer.new(resource).serialize
```

Example above produces this output (made readable for docs):

```json
{
  "data": {
    "id": "1",
    "type": "restaurant",
    "attributes": {
      "name": "big burgers"
    }
  }
}
```

#### Resource Collection

```crystal
resources = [Restaurant.new, Restaurant.new]
RestaurantSerializer.new(resources).serialize

```

Example above produces this output (made readable for docs):

```json
{
  "data": [
    {
      "id": "1",
      "type": "restaurant",
      "attributes": {
        "name": "big burgers"
      }
    },
    {
      "id": "2",
      "type": "restaurant",
      "attributes": {
        "name": "big sandwiches"
      }
    }
  ]
}
```

### Type

By default, the JSON-API type key will be the *snake_case* name of the resource class i.e. `AdminUser -> "admin_user"`.
You can override this behaviour by setting the `type(String)` macro.

```crystal
class AdminUserSerializer < FastJSONAPISerializer::Base(AdminUser)
  type "user"
  attribute :name
end
```

Example above produces this output (made readable for docs):

```json
{
  "data": {
    "id": "1",
    "type": "user",
    "attributes": {
      "name": "Joe"
    }
  }
}
```

### ID

Your resource class should have an id instance method or getter to populate the JSON `id` field of the resource.

#### Supported ID's

- Integer
- String
- UUID
- Nil

If the resource does not respond to `id` the JSON `id` value will become `null` - giving a little more flexibility, although not advised or complaint with the `JSON-API` standard.

> IMPORTANT - As per the [JSON-API](https://jsonapi.org) standard, we always convert the id to a string.

Example without and id below;

```crystal
class Restaurant
  property name

  def initialize(@name = "big burgers")
  end
end

class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name
end

RestaurantSerializer.new(Restaurant.new).serialize
```

Example above produces this output (made readable for docs):

```json
{
  "data": {
    "id": null,
    "type": "restaurant",
    "attributes": {
      "name": "big burgers"
    }
  }
}
```

### Attributes

The attributes API is very flexible.

**Single** `attribute`

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name
  attribute :street
end
```

**Multiple** `attributes`

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attributes :name, :street
end
```

**Mixed**

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attributes :name, :street
  attribute :post_code
end
```

**Serializer methods**

You can also list `attributes` which are on the serializer class;

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name
  attribute :custom_method_on_serializer

  def custom_method_on_serializer
    123
  end
end
```

#### Control the attribute JSON key name

Let's say you want to have different key name or case, you can pass this as a second argument `attribute`

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name, :FullName
end
```

Example above produces this output (made readable for docs):

```json
{
  "data": {
    "id": "1",
    "type": "restaurant",
    "attributes": {
      "FullName": "big burgers"
    }
  }
}
```

#### Conditional control of the attributes

**Attribute API**

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name, :FullName, if: :should_show_name

  def should_show_name(object, _options)
    object.has_full_name?
  end
end

RestaurantSerializer.new(Restaurant.new).serialize
```

OR

Use the `serialize(options: ...)` API to control the attributes

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name, :FullName, if: :should_show_name

  def should_show_name(object, options)
    object.has_full_name? && options[:allow_name]
  end
end

RestaurantSerializer.new(Restaurant.new).serialize(
  options: {:allow_name => true}
)
```

**Serialize API**

We can have any number of attributes which can be excluded on demand.

Use the `serialize(except: ...)` API to control the attributes

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name, :address, :post_code
end

RestaurantSerializer.new(Restaurant.new).serialize(
  except: %i(name postcode)
)
```

Example above produces this output (made readable for docs):

```json
{
  "data": {
    "id": "1",
    "type": "restaurant",
    "attributes": {
      "address": "somewhere cool"
    }
  }
}
```

### Relations

The following relationships are supported:

- `belongs_to`
- `has_many`
- `has_one`

Given a model which has various associations like follows:

```crystal
class Restaurant
  property id : String,
    name : String,
    address : Nil | Address = nil,
    post_code : Nil | PostCode = nil,
    rooms : Array(Room) = [] of Room

  def initialize(@id, @name = "big burgers")
  end

  def tables
    [Table.new(1), Table.new(2), Table.new(3)]
  end
end
```

You can define the serializer relationships

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name

  belongs_to :address, AddressSerializer

  has_one :post_code, PostCodeSerializer

  has_many :rooms, RoomSerializer
  has_many :tables, TableSerializer, :Tables # here we can override the name (optional)
end

# Or if you prefer a more explicit approach

class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  attribute :name

  belongs_to :address, serializer: AddressSerializer

  has_one :post_code, serializer: PostCodeSerializer

  has_many :rooms, serializer: RoomSerializer
  has_many :tables, serializer: TableSerializer, key: :Tables
end
```

Make sure to use the `serialize(includes: ...)` API to include the relations:

```
# build all associations
resource = Restaurant.new
resource.address = Address.new
resource.post_code = PostCode.new
room = Room.new(1)
room.tables = [Table.new(1), Table.new(2)]
resource.rooms = [room]

RestaurantSerializer.new(resource).serialize(
  includes: {
    :address   => [:address],
    :post_code => [:post_code],
    :tables    => {:room => [:room]}, # notice nested associations also
  }
)
```

> **IMPORTANT** - Relationships do nothing unless requested via the `serialize(includes: ...)` API

Example above produces this output (made readable for docs):

```json
{
  "data": {
    "id": "1",
    "type": "restaurant",
    "attributes": {
      "name": "big burgers"
    },
    "relationships": {
      "address": {
        "data": {
          "id": "101",
          "type": "address"
        }
      },
      "post_code": {
        "data": {
          "id": "101",
          "type": "post_code"
        }
      },
      "Tables": {
        "data": [
          {
            "id": "1",
            "type": "table"
          },
          {
            "id": "2",
            "type": "table"
          },
          {
            "id": "3",
            "type": "table"
          }
        ]
      }
    }
  },
  "included": [
    {
      "id": "101",
      "type": "address",
      "attributes": {
        "street": "some street"
      }
    },
    {
      "id": "101",
      "type": "post_code",
      "attributes": {
        "code": "code 24"
      }
    },
    {
      "id": "1",
      "type": "room",
      "attributes": {
        "name": "1-name"
      },
      "relationships": {}
    },
    {
      "id": "1",
      "type": "table",
      "attributes": {
        "number": 1
      },
      "relationships": {
        "room": {
          "data": {
            "id": "1",
            "type": "room"
          }
        }
      }
    },
    {
      "id": "2",
      "type": "room",
      "attributes": {
        "name": "2-name"
      },
      "relationships": {}
    },
    {
      "id": "2",
      "type": "table",
      "attributes": {
        "number": 2
      },
      "relationships": {
        "room": {
          "data": {
            "id": "2",
            "type": "room"
          }
        }
      }
    },
    {
      "id": "3",
      "type": "room",
      "attributes": {
        "name": "3-name"
      },
      "relationships": {}
    },
    {
      "id": "3",
      "type": "table",
      "attributes": {
        "number": 3
      },
      "relationships": {
        "room": {
          "data": {
            "id": "3",
            "type": "room"
          }
        }
      }
    }
  ]
}
```

### Meta

You can add meta details to the JSON response payload.

**Serialize API**

Use the `serialize(meta: ...)` API to control the meta attributes

```crystal
RestaurantSerializer.new(Restaurant.new).serialize(
  meta: {:page => 0, :limit => 50}
)
```

Example above produces this output (made readable for docs):

```json
{
  "data": {
    "id": "1",
    "type": "restaurant",
    "attributes": {
      "name": "big burgers"
    }
  },
  "meta": {
    "page": 0,
    "limit": 50
  }
}
```

**.meta class method**

You can define default meta attributes as a class method on the serializer.

Using the `serialize(meta: ...)` API you can **merge** or **override** the default meta attributes

```crystal
class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  def self.meta(options)
    {
      :status => "ok"
    } of Symbol => FastJSONAPISerializer::MetaAny
  end
end

RestaurantSerializer.new(Restaurant.new).serialize(
  meta: {:page => 0, :limit => 50}
)
```

> Note - `FastJSONAPISerializer::MetaAny` -> (JSON::Any::Type | Int32)

Example above produces this output (made readable for docs):

```json
{
  "data": {
    "id": "1",
    "type": "restaurant",
    "attributes": {
      "name": "big burgers"
    }
  },
  "meta": {
    "status": "ok",
    "page": 0,
    "limit": 50
  }
}
```

### Serialize API

We covered all the options in the previous examples but this shows all available options.

- `except` - array of fields which should be excluded
- `includes` - definition of relation that should be included
- `options` - options that will be passed to methods defined for `if` attribute options and `.meta(options)`
- `meta` - meta attributes to be added under `"meta"` key at root level, merged into default `.meta`

Kitchen sink example:

```crystal
RestaurantSerializer.new(resource).serialize(
  except: %i(name),
  includes: {
    :address   => [:address],
    :post_code => [:post_code],
    :tables    => {:room => [:room]},
  },
  meta: {:page => 0, :limit => 50},
  options: {:show_rating => true}
)
```

### Inheritance

You can DRY your serializers with inheritance - just add required attributes and/or associations in the subclasses.

```
class UserSerializer < Serializer::Base(User)
  attributes :name, :age
end

class FullUserSerializer < UserSerializer
  attributes :email, :created_at

  has_many :identities, IdentitySerializer
end
```

## TODO

- Allow Proc based conditional attributes
- Allow Proc based conditional relationships
- Allow global key case-change option
- Allow links meta data
- Add safety checks for inputs and bad data

## Contributing

1. Fork it (<https://github.com/mjeffrey18/fast-jsonapi-serializer-cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Acknowledgements

This project was based on concepts gather from another amazing open source shard - [serializer](https://github.com/imdrasil/serializer)

Thank you so much for the inspiration!

--

I did use this shard as a bench comparison, but with good intentions. Big shout out to [jsonapi-serializer-cr](https://github.com/andersondanilo/jsonapi-serializer-cr)

This project is awesome and has helped me build projects, great work!

## Contributors

- [Marc Jeffrey](https://github.com/mjeffrey18) - creator and maintainer
