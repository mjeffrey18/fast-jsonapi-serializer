module FastJSONAPISerializer
  # Contains DSL required to define required fields and relations for serialization.
  #
  # ```
  # class UserSerializer < FastJSONAPISerializer::Base(User)
  #   attribute :name
  #   attribute :first_name, "first-name"
  #   attribute :email, if: :secure?
  #
  #   has_many :posts, PostSerializer
  #
  #   def secure?(record, options)
  #     options && options[:secure]?
  #   end
  # end
  # ```
  module DSL
    # Defines list of attributes to be serialized from resource.
    #
    # ```
    # class UserSerializer < FastJSONAPISerializer::Base(User)
    #   attributes :name, :first_name, :email
    # end
    # ```
    macro attributes(*names)
      {%
        names.reduce(ATTRIBUTES) do |hash, name|
          hash[name] = {key: name, if: nil}
          hash
        end
      %}
    end

    # Defines *name* attribute to be serialized.
    #
    # *name* values will be used as a method name that is called on resource object.
    #
    # Example 1
    #
    # Given a user resource class with a instance method or getter
    #
    # ```
    # class User
    #   getter :age
    #
    #   def name
    #     "Joe"
    #   end
    # end
    # ```
    #
    # The serializer will call on those resource attributes
    #
    # ```
    # class UserSerializer < FastJSONAPISerializer::Base(User)
    #   attribute :name
    #   attribute :age
    # end
    # ```
    #
    # Example 2
    #
    # Attributes can be a serializer's own method name. In such case it is called instead.
    #
    # Given a user resource class with a instance method or getter
    #
    # ```
    # class User
    #   getter :age
    #
    #   def name
    #     "Joe"
    #   end
    # end
    # ```
    #
    # The serializer will call its own method name
    #
    # ```
    # class UserSerializer < FastJSONAPISerializer::Base(User)
    #   attribute :name
    #   attribute :age
    #
    #   # this method will be called instead of user.name
    #   def name
    #     "Sally"
    #   end
    # end
    # ```
    #
    # Options:
    #
    # * *key* - json key; equals to *name* by default;
    # * *if* - name of a method to be used to check whether attribute *name* should be serialized.
    #
    # Method given to the *if* should have following signature:
    #
    # `def method(object : T, options : Hash(Symbol, FastJSONAPISerializer::MetaAny)?)`
    #
    # Returned type will be used in `if` clause.
    #
    # ```
    # class UserSerializer < FastJSONAPISerializer::Base(User)
    #   attribute :name
    #   attribute :first_name, "first-name"
    #   attribute :email, if: :secure?
    #
    #   def secure?(record, options)
    #     options && options[:secure]?
    #   end
    # end
    # ```
    #
    # OR
    #
    # ```
    # class UserSerializer < FastJSONAPISerializer::Base(User)
    #   attribute :name
    #   attribute :first_name, key: "first-name"
    #   attribute :email, if: :secure?
    #
    #   def secure?(record, options)
    #     options && options[:secure]?
    #   end
    # end
    # ```
    # Whichever format you prefer.
    macro attribute(name, key = nil, if if_proc = nil)
      {% ATTRIBUTES[name] = {key: key || name, if: if_proc} %}
    end

    # Defines `one-to-many` *name* association that is serialized by *serializer*.
    #
    # Options:
    #
    # * *key* - json key; equals to *name* by default;
    # * *serializer* - class to be used for association serialization.
    #
    # ```
    # class UserSerializer < FastJSONAPISerializer::Base(User)
    #   has_many :posts, PostSerializer
    #   has_many :post_comments, CommentSerializer, "postComments"
    # end
    # ```
    #
    # OR
    #
    # ```
    # class UserSerializer < FastJSONAPISerializer::Base(User)
    #   has_many :posts, PostSerializer
    #   has_many :post_comments, serializer: CommentSerializer, key: "postComments"
    # end
    # ```
    #
    # Whichever format you prefer.
    #
    # By default all associations are not serialized. To make an association being serialized
    # it should be explicitly specified in *includes* argument of `Base#serialize` method.
    macro has_many(name, serializer, key = nil)
      {% RELATIONS[name] = {serializer: serializer, key: key || name, type: :has_many} %}
    end

    # Defines `one-to-one` *name* association that is serialized by *serializer*.
    #
    # For more details see `.has_many`.
    macro has_one(name, serializer, key = nil)
      {% RELATIONS[name] = {serializer: serializer, key: key || name, type: :has_one} %}
    end

    # Defines `one-to-any` *name* association that is serialized by *serializer*.
    #
    # For more details see `.has_many`.
    macro belongs_to(name, serializer, key = nil)
      {% RELATIONS[name] = {serializer: serializer, key: key || name, type: :belongs_to} %}
    end
  end
end
