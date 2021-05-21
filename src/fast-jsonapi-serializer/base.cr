require "./dsl"

module FastJSONAPISerializer
  # Allowed types for *meta* hash values.
  alias MetaAny = JSON::Any::Type | Int32

  # Base serialization superclass.
  #
  # Considering you have various models - which can be from an ORM or just simple classes
  #
  # ```
  # class Address
  #   getter id
  #   property street
  #
  #   def initialize(@id = 101, @street = "some street")
  #   end
  # end
  #
  # class PostCode
  #   getter id
  #   property code
  #
  #   def initialize(@id = 101, @code = "code 24")
  #   end
  # end
  #
  # class Restaurant
  #   property name,
  #     address : Nil | Address = nil,
  #     post_code : Nil | PostCode = nil,
  #     rooms : Array(Room) = [] of Room
  #
  #   def initialize(@name = "big burgers")
  #   end
  #
  #   def rating
  #     "Great!"
  #   end
  #
  #   # optional static id
  #   def id
  #     1
  #   end
  #
  #   def tables
  #     [Table.new(1), Table.new(2), Table.new(3)]
  #   end
  # end
  #
  # class Room
  #   property id : Int32 = 1,
  #     tables : Array(Table) = [] of Table
  #
  #   def initialize(@id)
  #   end
  #
  #   def name
  #     "#{id}-name"
  #   end
  # end
  #
  # class Table
  #   property number
  #
  #   def initialize(@number = 1)
  #   end
  #
  #   def room
  #     Room.new(number)
  #   end
  #
  #   def id
  #     number
  #   end
  # end
  # ```
  # You can define various serializers
  #
  # ```
  # class AddressSerializer < FastJSONAPISerializer::Base(Address)
  #   attributes :street
  #   type "address" # be specific about the JSON-API type - default to Model camelcase
  # end
  #
  # class PostCodeSerializer < FastJSONAPISerializer::Base(PostCode)
  #   attributes :code
  # end
  #
  # class RestaurantSerializer < FastJSONAPISerializer::Base(Restaurant)
  #   attribute :name
  #   attribute :rating, :Rating, if: :test_rating
  #   attribute :own_field
  #
  #   belongs_to :address, serializer: AddressSerializer # option key-word args
  #
  #   has_one :post_code, PostCodeSerializer
  #
  #   has_many :rooms, RoomSerializer
  #   has_many :tables, TableSerializer, :Tables
  #
  #   def test_rating(object, options)
  #     options.nil? || !options[:test]?
  #   end
  #
  #   def own_field
  #     12
  #   end
  #
  #   # default meta
  #   def self.meta(*options)
  #     {:page => 0}
  #   end
  # end
  #
  # class RoomSerializer < FastJSONAPISerializer::Base(Room)
  #   attribute :name
  #
  #   has_many :tables, TableSerializer
  # end
  #
  # class TableSerializer < FastJSONAPISerializer::Base(Table)
  #   attribute :number
  #
  #   belongs_to :room, RoomSerializer
  # end
  # ```
  #
  # Build your serialized json
  #
  # ```
  # resource = Restaurant.new
  # resource.address = Address.new
  # resource.post_code = PostCode.new
  # room = Room.new(1)
  # room.tables = [Table.new(1), Table.new(2)]
  # resource.rooms = [room]
  #
  # RestaurantSerializer.new(resource).serialize(
  #   except: %i(name),
  #   includes: {
  #     :address   => [:address],
  #     :post_code => [:post_code],
  #     :tables    => {:room => [:room]},
  #   },
  #   meta: {:page => 0, :limit => 50},
  #   options: {:test => true}
  # )
  # ```
  #
  # Example above produces next output (this one is made to be readable -
  # real one has no newlines and indentations):
  #
  # ```json
  # {
  #   "data": {
  #     "id": "1",
  #     "type": "restaurant",
  #     "attributes": {
  #       "own_field": 12
  #     },
  #     "relationships": {
  #       "address": {
  #         "data": {
  #           "id": "101",
  #           "type": "address"
  #         }
  #       },
  #       "post_code": {
  #         "data": {
  #           "id": "101",
  #           "type": "post_code"
  #         }
  #       },
  #       "Tables": {
  #         "data": [
  #           {
  #             "id": "1",
  #             "type": "table"
  #           },
  #           {
  #             "id": "2",
  #             "type": "table"
  #           },
  #           {
  #             "id": "3",
  #             "type": "table"
  #           }
  #         ]
  #       }
  #     }
  #   },
  #   "included": [
  #     {
  #       "id": "101",
  #       "type": "address",
  #       "attributes": {
  #         "street": "some street"
  #       }
  #     },
  #     {
  #       "id": "101",
  #       "type": "post_code",
  #       "attributes": {
  #         "code": "code 24"
  #       }
  #     },
  #     {
  #       "id": "1",
  #       "type": "room",
  #       "attributes": {
  #         "name": "1-name"
  #       },
  #       "relationships": {}
  #     },
  #     {
  #       "id": "1",
  #       "type": "table",
  #       "attributes": {
  #         "number": 1
  #       },
  #       "relationships": {
  #         "room": {
  #           "data": {
  #             "id": "1",
  #             "type": "room"
  #           }
  #         }
  #       }
  #     },
  #     {
  #       "id": "2",
  #       "type": "room",
  #       "attributes": {
  #         "name": "2-name"
  #       },
  #       "relationships": {}
  #     },
  #     {
  #       "id": "2",
  #       "type": "table",
  #       "attributes": {
  #         "number": 2
  #       },
  #       "relationships": {
  #         "room": {
  #           "data": {
  #             "id": "2",
  #             "type": "room"
  #           }
  #         }
  #       }
  #     },
  #     {
  #       "id": "3",
  #       "type": "room",
  #       "attributes": {
  #         "name": "3-name"
  #       },
  #       "relationships": {}
  #     },
  #     {
  #       "id": "3",
  #       "type": "table",
  #       "attributes": {
  #         "number": 3
  #       },
  #       "relationships": {
  #         "room": {
  #           "data": {
  #             "id": "3",
  #             "type": "room"
  #           }
  #         }
  #       }
  #     }
  #   ],
  #   "meta": {
  #     "page": 0,
  #     "limit": 50
  #   }
  # }
  # ```
  #
  # For a details about DSL specification see `DSL`.
  #
  # ## Inheritance
  #
  # You can DRY your serializers by inheritance - just add required attributes and/or associations in
  # the subclasses.
  #
  # ```
  # class UserSerializer < Serializer::Base(User)
  #   attributes :name, :age
  # end
  #
  # class FullUserSerializer < UserSerializer
  #   attributes :email, :created_at
  #
  #   has_many :identities, IdentitySerializer
  # end
  # ```
  abstract class Base(T)
    include DSL

    # Set the json-api type directly for this resource
    #
    # ```
    # class AdminUserSerializer < FastJSONAPISerializer::Base(AdminUser)
    #   type "user"
    #   attributes :name, :age
    # end
    # ```
    #
    # ```
    # serializer = AdminUserSerializer.new(AdminUser.first)
    # serializer.get_type # => `user`
    # ```
    private macro type(name)
      def get_type : String
        {{name}}
      end
    end

    # :nodoc:
    macro define_serialization
      macro finished
        {% verbatim do %}
          {% superclass = @type.superclass %}

          {% if ATTRIBUTES.size > 0 %}

            # we call super on this method to build inherited attributes first
            # then build current serializer attributes thereafter
            # :nodoc:
            protected def build_attributes(object, io, except, options)
              fields_count = {{ superclass.methods.any?(&.name.==(:build_attributes.id)) ? :super.id : 0 }}
              {% for name, props in ATTRIBUTES %}
                {% resource = @type.has_method?(name) ? :self : :object %}
                if !except.includes?(:{{name.id}}) {% if props[:if] %} && {{props[:if].id}}(object, options) {% end %}
                  io << "," unless fields_count.zero?
                  fields_count += 1
                  io << "\"{{props[:key].id}}\":" << {{resource.id}}.{{name.id}}.to_json
                end
              {% end %}
              fields_count
            end

            # Top level attributes namespace builder
            # :nodoc:
            protected def serialize_attributes(object, io, except, options)
              io << "\"id\":"
              if object.responds_to?(:id)
                id_converter(io, object.id)
              else
                io << "null"
              end
              io << ","
              io << "\"type\":" << get_type.to_json << ","
              io << "\"attributes\":"
              io << "{"
              build_attributes(object, io, except, options)
              io << "}"
            end
          {% end %}

          {% if RELATIONS.size > 0 %}

            # Builds individual relations data with included Set updated with the serialized object
            # :nodoc:
            protected def build_relation(io, name, props, sub_object, includes, options, included, included_keys)
              serializer = props[:serializer].new(sub_object, included, included_keys)
              io << "{"
              io << "\"id\":"
              if sub_object.responds_to?(:id)
                id_converter(io, sub_object.id)
              else
                io << "null"
              end
              io << ","
              io << "\"type\":" << serializer.get_type.to_json
              io << "}"

              if included_keys.add?(serializer.unique_key(sub_object))
                data = String.build do |included_io|
                  serializer._serialize_json(sub_object, included_io, [] of Symbol, nested_includes(name, includes), options)
                end
                included.add(data)
              end
            end

            # This is all a bit hairy, TBH, it is hairy..
            # We first call super on this method to build inherited relationships.
            # Then we build the current serializer relationships thereafter
            # The logic runs through all the relationships defined via the DSL and builds the json if the `serializer(includes: ...)` args have been passed.
            # :nodoc:
            protected def build_relationships(object, io, includes, options, included, included_keys)
              fields_count = {{ superclass.methods.any?(&.name.==(:build_relationships.id)) ? :super.id : 0 }}

              {% for name, props in RELATIONS %}
                if has_relation?({{name}}, includes)
                  io << "," unless fields_count.zero?
                  io << "\"{{props[:key].id}}\":{"
                  io << "\"data\":"

                  # for has_many we need to build a array
                  {% if props[:type] == :has_many %}
                    io << "["
                    has_many_fields_count = 0
                    unless object.{{name.id}}.empty?
                      object.{{name.id}}.each_with_index do |sub_object, index|
                        io << "," unless has_many_fields_count.zero?
                        has_many_fields_count += 1
                        build_relation(io, {{name}}, {{props}}, sub_object, includes, options, included, included_keys)
                      end
                    end
                    io << "]"

                  # for has_one or belongs_to we need to build an object
                  {% elsif props[:type] == :has_one || props[:type] == :belongs_to %}
                    sub_object = object.{{name.id}}
                    if sub_object
                      build_relation(io, {{name}}, {{props}}, sub_object, includes, options, included, included_keys)
                    else
                      io << "null"
                    end
                  {% end %}

                  io << "}"
                  fields_count += 1
                end
                fields_count
              {% end %}
            end

            # Top level relations namespace builder
            # We pass in @_included, @_included_keys from this top level serializer
            # all inherited or association serializers will work with this variable to ensure
            # we have unique included array in the final payload
            # :nodoc:
            protected def serialize_relations(object, io, includes, options)
              return if includes.empty?

              io << ",\"relationships\":{"
              build_relationships(object, io, includes, options, @_included, @_included_keys)
              io << "}"
              return
            end
          {% end %}
        {% end %}
      end
    end

    # :nodoc:
    macro inherited
      define_serialization
      # :nodoc:
      ATTRIBUTES = {} of Nil => Nil
      # :nodoc:
      RELATIONS = {} of Nil => Nil
    end

    # Returns default meta options.
    #
    # If this is empty and no additional meta-options are given - `meta` key is avoided. To define own default meta options
    # just override this in your serializer:
    #
    # ```
    # class UserSerializer < FastJSONAPISerializer::Base(User)
    #   def self.meta(options)
    #     {
    #       :status => "ok",
    #     } of Symbol => FastJSONAPISerializer::MetaAny
    #   end
    # end
    # ```
    def self.meta(_options)
      {} of Symbol => MetaAny
    end

    # Resource to be serialized.
    protected getter resource
    # Contains unique set of all included serialized relationships
    private getter _included : Set(String)
    # Contains unique set of all serializer keys to ensure we do not add the same included twice
    private getter _included_keys : Set(Tuple(String, Int32))

    # Only use @resource
    #
    # ```
    # serializer = RestaurantSerializer.new(resource)
    # ```
    #
    # @_included and @_included_keys are used internally to build child serializers via associations
    def initialize(@resource : T | Array(T)?, @_included = Set(String).new, @_included_keys = Set(Tuple(String, Int32)).new)
    end

    # Generates a JSON formatted string.
    #
    # Arguments:
    #
    # * `except` - array of fields which should be excluded
    # * `includes` - definition of relation that should be included
    # * `options` - options that will be passed to methods defined for `if` attribute options and `.meta(options)`
    # * `meta` - meta attributes to be added under `"meta"` key at root level, merged into default `.meta`
    #
    # ```
    # RestaurantSerializer.new(resource).serialize(
    #   except: %i(name),
    #   includes: {
    #     :address   => [:address],
    #     :post_code => [:post_code],
    #     :tables    => {:room => [:room]},
    #   },
    #   meta: {:page => 0, :limit => 50},
    #   options: {:test => true}
    # )
    # ```
    #
    # ## Includes
    #
    # *includes* option accepts `Array` or `Hash` values. To define just a list of association of resource object - just pass an array:
    #
    # ```
    # RestaurantSerializer.new(object).serialize(includes: [:tables])
    # ```
    #
    # You can also specify deeper and more sophisticated schema by passing `Hash`. In this case hash values should be of
    # `Array(Symbol) | Hash | Nil` type. `nil` is used to mark association which name is used for key as a leaf in schema
    # tree.
    def serialize(except : Array(Symbol) = %i(), includes : Array(Symbol) | Hash = %i(), options : Hash? = nil, meta : Hash(Symbol, MetaAny)? = nil)
      String.build do |io|
        build(io, except, includes, options, meta)
      end
    end

    # Default serializer `type`
    # If class macro `type(str : String)` is not used the type will based on the object passed to the serializer
    #
    # Format: will be underscore and downcase
    #
    # ```
    # class AdminUserSerializer < FastJSONAPISerializer::Base(AdminUser)
    #   attributes :name, :age
    # end
    # ```
    #
    # ```
    # serializer = AdminUserSerializer.new(AdminUser.first)
    # serializer.get_type # => `admin_user`
    # ```
    def get_type : String
      T.name.underscore.downcase
    end

    # builds de-duplication key to be used by @_included_keys(Set)
    def unique_key(object)
      {get_type, object.id}
    end

    # :nodoc:
    protected def build(io : IO, except : Array, includes : Array | Hash, options : Hash?, meta)
      io << "{\"data\":"
      _serialize_json(resource, io, except, includes, options)
      default_meta = self.class.meta(options)
      unless meta.nil?
        meta.each do |key, value|
          default_meta[key] = value
        end
      end
      fields_count = 0
      unless @_included.empty?
        io << %(,"included":[)
        @_included.each_with_index do |json, index|
          io << "," unless fields_count.zero?
          fields_count += 1
          io << json
        end
        io << "]"
      end
      io << %(,"meta":) << default_meta.to_json if default_meta.any?
      io << "}"
    end

    # :nodoc:
    protected def serialize_attributes(object, io, except, options)
    end

    # :nodoc:
    protected def serialize_relations(object, io, includes, options)
    end

    # Returns whether *includes* has a mention for relation *name*.
    # :nodoc:
    protected def has_relation?(name, includes : Array)
      includes.includes?(name)
    end

    # :nodoc:
    protected def has_relation?(name, includes : Hash)
      includes.has_key?(name)
    end

    # Returns nested inclusions for relation *name*.
    # :nodoc:
    protected def nested_includes(name, includes : Array)
      %i()
    end

    # :nodoc:
    protected def nested_includes(name, includes : Hash)
      includes[name] || %i()
    end

    # :nodoc:
    protected def _serialize_json(object : T, io : IO, except : Array, includes : Array | Hash, options : Hash?)
      io << "{"
      serialize_attributes(object, io, except, options)
      serialize_relations(object, io, includes, options)
      io << "}"
    end

    # :nodoc:
    protected def _serialize_json(collection : Array(T), io : IO, except : Array, includes : Array | Hash, options : Hash?)
      io << "["
      collection.each_with_index do |object, index|
        io << "," if index != 0
        _serialize_json(object, io, except, includes, options)
      end
      io << "]"
    end

    # :nodoc:
    protected def _serialize_json(object : Nil, io : IO, except : Array, includes : Array | Hash, options : Hash?)
      io << "null"
    end

    # :nodoc:
    protected def id_converter(io, id)
      case id
      when Number then io << "\"" << id << "\""
      else             io << id.to_json
      end
    end
  end
end
