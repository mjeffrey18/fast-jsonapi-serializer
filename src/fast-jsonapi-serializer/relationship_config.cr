module FastJSONAPISerializer
  class RelationshipConfig
    class RelationshipMissingException < Exception
      def initialize(relation : Symbol?)
        @message = if relation
                     "'#{relation}' association missing."
                   else
                     "Associations are not configured."
                   end
      end
    end

    getter name : Symbol?
    getter children : Array(RelationshipConfig)?
    getter included = true

    def initialize(@name = nil, @children = nil)
    end

    def include?(@included)
      children.try &.each { |child| child.include?(@included) }

      self
    end

    def has_relation?(name : Symbol)
      children.try &.any? { |rel| rel.name == name }
    end

    def nested(name : Symbol)
      null_rel = self.class.new

      children.try &.find(null_rel) { |rel| rel.name == name } || null_rel
    end

    def empty?
      children.nil? || children.try &.empty?
    end

    def relationship(path)
      raise RelationshipMissingException.new(nil) if children.nil?

      rel = children.not_nil!.find { |child| child.name == path }
      raise RelationshipMissingException.new(path) if rel.nil?
      rel
    end

    def self.parse(config : Iterable)
      new(nil, build(config))
    end

    def self.build(arr : Array)
      arr.map { |rel| self.build(rel) }
    end

    def self.build(hash : Hash)
      hash.map do |rel_name, rels|
        child = build(rels)
        if child.is_a? Iterable
          new(rel_name, child)
        else
          new(rel_name, [child])
        end
      end
    end

    def self.build(name : Symbol)
      new(name)
    end
  end
end
