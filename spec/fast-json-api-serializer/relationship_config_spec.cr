require "../spec_helper"

describe FastJSONAPISerializer::RelationshipConfig do
  context "when config contains hashes" do
    it "parses configuration" do
      configuration = { :a => { :b => :c } }
      config = FastJSONAPISerializer::RelationshipConfig.parse(configuration)
      config.included.should be_true
      config.empty?.should be_false

      expect_raises(FastJSONAPISerializer::RelationshipConfig::RelationshipMissingException) do
        config.relationship(:a).relationship(:c)
      end

      config.has_relation?(:a).should be_true
      config.relationship(:a).empty?.should be_false
      config.relationship(:a).included.should be_true
      config.has_relation?(:d).should be_false
      config.nested(:d).included.should be_true

      config.relationship(:a).has_relation?(:b).should be_true
      config.relationship(:a).relationship(:b).empty?.should be_false
      config.relationship(:a).relationship(:b).included.should be_true
      config.relationship(:a).relationship(:b).has_relation?(:d).should be_false

      config.relationship(:a).relationship(:b).include?(false)
      config.relationship(:a).relationship(:b).empty?.should be_false
      config.relationship(:a).relationship(:b).included.should be_false
      config.relationship(:a).relationship(:b).has_relation?(:c).should be_true

      config.relationship(:a).relationship(:b).relationship(:c).empty?.should be_true
      config.relationship(:a).relationship(:b).relationship(:c).included.should be_false

      config.nested(:d).nested(:g).included.should be_true
    end
  end

  context "when config contains array" do
    it "parses configuration" do
      configuration = { :a => { :b => [:c] } }
      config = FastJSONAPISerializer::RelationshipConfig.parse(configuration)
      config.included.should be_true
      config.empty?.should be_false

      expect_raises(FastJSONAPISerializer::RelationshipConfig::RelationshipMissingException) do
        config.relationship(:a).relationship(:c)
      end

      config.has_relation?(:a).should be_true
      config.relationship(:a).empty?.should be_false
      config.relationship(:a).included.should be_true
      config.has_relation?(:d).should be_false
      config.nested(:d).included.should be_true

      config.relationship(:a).has_relation?(:b).should be_true
      config.relationship(:a).relationship(:b).empty?.should be_false
      config.relationship(:a).relationship(:b).included.should be_true
      config.relationship(:a).relationship(:b).has_relation?(:d).should be_false

      config.relationship(:a).relationship(:b).include?(false)
      config.relationship(:a).relationship(:b).empty?.should be_false
      config.relationship(:a).relationship(:b).included.should be_false
      config.relationship(:a).relationship(:b).has_relation?(:c).should be_true

      config.relationship(:a).relationship(:b).relationship(:c).empty?.should be_true
      config.relationship(:a).relationship(:b).relationship(:c).included.should be_false

      config.nested(:d).nested(:g).included.should be_true
    end
  end
end
