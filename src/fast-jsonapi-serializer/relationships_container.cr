module FastJSONAPISerializer
  class RelationshipsContainer
    property content = Set(String).new
    property included_keys = Set(Tuple(String, IDAny)).new

    delegate :empty?, to: included_keys

    def add?(item : Tuple(String, IDAny))
      included_keys.add?(item)
    end

    def include_content(item : String)
      content.add(item)
    end
  end
end
