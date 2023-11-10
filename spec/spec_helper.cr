require "spec"
require "../src/fast-jsonapi-serializer/relationship_config"
require "../src/fast-jsonapi-serializer"
require "./support/**"

def validate_json_integrity(json_string : String)
  JSON.parse(json_string).should be_a(JSON::Any)
end
