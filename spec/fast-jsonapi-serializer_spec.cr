require "./spec_helper"

# these tests don't look the best with the huge amount of data output...
# but they fast, easy and checks integrity on any changes so gets the job done...
describe FastJSONAPISerializer do
  describe ".new" do
    it "accepts object" do
      RestaurantSerializer.new(Restaurant.new)
    end

    it "accepts collection" do
      RestaurantSerializer.new([Restaurant.new])
    end

    it "accepts nil" do
      RestaurantSerializer.new(nil)
    end
  end

  describe ".type(String)" do
    it "accepts a type override" do
      data = AddressWithTypeSerializer.new(Address.new).serialize
      data.should eq("{\"data\":{\"id\":\"101\",\"type\":\"my_address\",\"attributes\":{\"street\":\"some street\"}}}")
      validate_json_integrity(data)
    end
  end

  describe "#serialize" do
    it "serializes attributes correctly with single object" do
      data = RestaurantSerializer.new(Restaurant.new).serialize
      data.should_not contain(%("relationships"))
      data.should_not contain(%("included"))
      data.should eq("{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12}}}")
      validate_json_integrity(data)
    end

    it "serializes attributes correctly with collection" do
      data = RestaurantSerializer.new([Restaurant.new]).serialize
      data.should_not contain(%("relationships"))
      data.should_not contain(%("included"))
      data.should eq("{\"data\":[{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12}}]}")
      validate_json_integrity(data)
    end

    it "serializes attributes correctly with null" do
      data = RestaurantSerializer.new(nil).serialize
      data.should_not contain(%("relationships"))
      data.should_not contain(%("included"))
      data.should eq("{\"data\":null}")
      validate_json_integrity(data)
    end

    context "with objects without ids" do
      it "accepts object and returns correct attributes" do
        data = RestaurantWithoutIdSerializer.new(RestaurantWithoutId.new).serialize
        data.should eq("{\"data\":{\"id\":null,\"type\":\"restaurant_without_id\",\"attributes\":{\"name\":\"big burgers\"}}}")
        validate_json_integrity(data)
      end

      it "accepts collection and returns correct attributes" do
        data = RestaurantWithoutIdSerializer.new([RestaurantWithoutId.new]).serialize
        data.should eq("{\"data\":[{\"id\":null,\"type\":\"restaurant_without_id\",\"attributes\":{\"name\":\"big burgers\"}}]}")
        validate_json_integrity(data)
      end
    end

    context "with id variants" do
      it "accepts object with UUID id and returns correct attributes" do
        id = UUID.random
        data = AddressWithUUIDSerializer.new(AddressWithUUID.new(id: id)).serialize
        data.should eq("{\"data\":{\"id\":\"#{id}\",\"type\":\"address_with_uuid\",\"attributes\":{\"street\":\"some street\"}}}")
        validate_json_integrity(data)
      end

      it "accepts object with String id and returns correct attributes" do
        id = Random.new.hex
        data = AddressWithStringSerializer.new(AddressWithString.new(id: id)).serialize
        data.should eq("{\"data\":{\"id\":\"#{id}\",\"type\":\"address_with_string\",\"attributes\":{\"street\":\"some street\"}}}")
        validate_json_integrity(data)
      end
    end

    it "allows inheritance attributes" do
      resource = Restaurant.new
      resource.guests = [Guest.new(123), Guest.new(456)]
      data = InheritedSerializer.new(resource).serialize(
        includes: {
          :guests      => [:guests],
          :more_guests => [:more_guests],
        },
      )
      data.should eq(
        "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12,\"inherited_field\":\"Restaurant 1.23\"},\"relationships\":{\"guests\":{\"data\":[{\"id\":\"123\",\"type\":\"guest\"},{\"id\":\"456\",\"type\":\"guest\"}]},\"more_guests\":{\"data\":[{\"id\":\"123\",\"type\":\"guest\"}]}}}" +
        ",\"included\":[{\"id\":\"123\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{}},{\"id\":\"456\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{}}]}"
      )
      validate_json_integrity(data)
    end

    it "accepts except args" do
      data = RestaurantSerializer.new(Restaurant.new).serialize(except: %i(name))
      data.should_not contain(%("name": "big burgers"))
      data.should eq("{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"Rating\":\"Great!\",\"own_field\":12}}}")
      validate_json_integrity(data)
    end

    it "accepts options args / attribute if: logic" do
      data = RestaurantSerializer.new(Restaurant.new).serialize(options: {:test => true})
      data.should_not contain(%("Rating"))
      data.should eq("{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"own_field\":\"custom-big burgers\"}}}")
      validate_json_integrity(data)
    end

    describe "meta" do
      it "accepts meta args" do
        data = RestaurantSerializer.new(Restaurant.new).serialize(meta: {:page => 0})
        data.should contain(%("meta"))
        data.should eq("{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12}},\"meta\":{\"page\":0}}")
        validate_json_integrity(data)
      end

      it "accepts meta args with default meta" do
        data = AddressWithMetaSerializer.new(Address.new).serialize
        data.should eq("{\"data\":{\"id\":\"101\",\"type\":\"address\",\"attributes\":{\"street\":\"some street\"}},\"meta\":{\"page\":0}}")
        validate_json_integrity(data)

        data = AddressWithMetaSerializer.new(Address.new).serialize(meta: {:total => 0})
        data.should eq("{\"data\":{\"id\":\"101\",\"type\":\"address\",\"attributes\":{\"street\":\"some street\"}},\"meta\":{\"page\":0,\"total\":0}}")
        validate_json_integrity(data)

        data = AddressWithMetaSerializer.new(Address.new).serialize(meta: {:page => 3})
        data.should eq("{\"data\":{\"id\":\"101\",\"type\":\"address\",\"attributes\":{\"street\":\"some street\"}},\"meta\":{\"page\":3}}")
        validate_json_integrity(data)
      end
    end

    describe "includes" do
      context "with belongs_to" do
        it "added includes objects to included data" do
          resource = Restaurant.new
          resource.address = Address.new
          data = RestaurantSerializer.new(resource).serialize(
            includes: {
              :address => [:address],
            },
          )
          data.should contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{\"address\":{\"data\":{\"id\":\"101\",\"type\":\"address\"}}}},\"included\":[{\"id\":\"101\",\"type\":\"address\",\"attributes\":{\"street\":\"some street\"}}]}"
          )
          validate_json_integrity(data)
        end

        it "adds relations objects and skips included data" do
          resource = Restaurant.new
          resource.address = Address.new
          rel_config = FastJSONAPISerializer::RelationshipConfig.parse({ :address => [:address] })
          rel_config.embed(false)
          data = RestaurantSerializer.new(resource).serialize(includes: rel_config)
          data.should contain(%("included"))
          data.should contain(%("relationships"))

          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{\"address\":{\"data\":{\"id\":\"101\",\"type\":\"address\"}}}},\"included\":[]}"
          )
          validate_json_integrity(data)
        end

        it "only includes objects to included data if relationship exists" do
          data = RestaurantSerializer.new(Restaurant.new).serialize(
            includes: {
              :address => [:address],
            },
          )
          data.should_not contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{\"address\":{\"data\":null}}}}"
          )
          validate_json_integrity(data)
        end

        it "ignores unknown includes" do
          resource = Restaurant.new
          resource.address = Address.new
          data = RestaurantSerializer.new(resource).serialize(
            includes: {
              :some_address => [:some_address],
            },
          )
          data.should_not contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq("{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{}}}")
          validate_json_integrity(data)
        end
      end

      context "with has_one" do
        it "added includes objects to included data" do
          resource = Restaurant.new
          resource.post_code = PostCode.new
          data = RestaurantSerializer.new(resource).serialize(
            includes: {
              :post_code => [:post_code],
            },
          )
          data.should contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{\"post_code\":{\"data\":{\"id\":\"101\",\"type\":\"post_code\"}}}},\"included\":[{\"id\":\"101\",\"type\":\"post_code\",\"attributes\":{\"code\":\"code 24\"}}]}"
          )
          validate_json_integrity(data)
        end

        it "includes only relationsips objects and skips embedding data" do
          rel_config = FastJSONAPISerializer::RelationshipConfig.parse({ :post_code => [:post_code] }).embed(false)
          resource = Restaurant.new
          resource.post_code = PostCode.new
          data = RestaurantSerializer.new(resource).serialize(includes: rel_config)
          data.should contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{\"post_code\":{\"data\":{\"id\":\"101\",\"type\":\"post_code\"}}}},\"included\":[]}"
          )
          validate_json_integrity(data)
        end

        it "only includes objects to included data if relationship exists" do
          data = RestaurantSerializer.new(Restaurant.new).serialize(
            includes: {
              :post_code => [:post_code],
            },
          )
          data.should_not contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{\"post_code\":{\"data\":null}}}}"
          )
          validate_json_integrity(data)
        end

        it "ignores unknown includes" do
          resource = Restaurant.new
          resource.post_code = PostCode.new
          data = RestaurantSerializer.new(resource).serialize(
            includes: {
              :some_post_code => [:some_post_code],
            },
          )
          data.should_not contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq("{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{}}}")
          validate_json_integrity(data)
        end
      end

      context "with has_many" do
        it "added includes objects to included data" do
          resource = Restaurant.new
          resource.rooms = [Room.new(1), Room.new(2)]
          data = RestaurantSerializer.new(resource).serialize(
            includes: {
              :rooms => [:rooms],
            },
          )
          data.should contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{\"rooms\":{\"data\":[{\"id\":\"1\",\"type\":\"room\"},{\"id\":\"2\",\"type\":\"room\"}]}}}" +
            ",\"included\":[{\"id\":\"1\",\"type\":\"room\",\"attributes\":{\"name\":\"1-name\"},\"relationships\":{}},{\"id\":\"2\",\"type\":\"room\",\"attributes\":{\"name\":\"2-name\"},\"relationships\":{}}]}"
          )
          validate_json_integrity(data)
        end

        it "adds relation objects and skips included data" do
          resource = Restaurant.new
          resource.rooms = [Room.new(1), Room.new(2)]
          ref_config = FastJSONAPISerializer::RelationshipConfig.parse({ :rooms => [:rooms] }).embed(false)
          data = RestaurantSerializer.new(resource).serialize(includes: ref_config)
          data.should contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{\"rooms\":{\"data\":[{\"id\":\"1\",\"type\":\"room\"},{\"id\":\"2\",\"type\":\"room\"}]}}}" +
            ",\"included\":[]}"
          )
          validate_json_integrity(data)
        end

        it "produces only includes objects to included data" do
          resource = Restaurant.new
          resource.guests = [Guest.new(1), Guest.new(2)]
          data = RestaurantSerializer.new(resource).serialize(
            includes: {
              :guests => [:guests],
              :vips   => [:vips],
            },
          )
          data.should contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{\"guests\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"}]},\"vips\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"}]}}}" +
            ",\"included\":[{\"id\":\"1\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{}},{\"id\":\"2\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{}}]}"
          )
          validate_json_integrity(data)
          json = JSON.parse(data)
          json["included"].size.should eq(2)
        end

        it "works with deeply nested objects" do
          resource = Restaurant.new
          resource.guests = [Guest.new(1), Guest.new(2)]
          data = RestaurantSerializer.new(resource).serialize(
            includes: {
              :guests => {:friends => [:friends]},
              :diners => [:diners],
              :vips   => [:vips],
            }
          )
          data.should contain(%("included"))
          data.should contain(%("relationships"))
          # restaurant has_many :guests
          # -- > guest has_many :friends -> which happens to other guests
          # so we include all restaurant guests and the guests.friends(Guests)
          # which uniquely returns a list of 4 guests in the included
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12}" +
            ",\"relationships\":{\"guests\":{\"data\":[" +
            "{\"id\":\"1\",\"type\":\"guest\"}," +
            "{\"id\":\"2\",\"type\":\"guest\"}]}," +
            "\"diners\":{\"data\":[{\"id\":\"60\",\"type\":\"guest\"}]}," +
            "\"vips\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"}]}}}" +
            ",\"included\":[" +
            "{\"id\":\"3\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"}}," +
            "{\"id\":\"2\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{\"friends\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"},{\"id\":\"3\",\"type\":\"guest\"}]}}}," +
            "{\"id\":\"1\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{\"friends\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"},{\"id\":\"3\",\"type\":\"guest\"}]}}}," +
            "{\"id\":\"60\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{}}]}"
          )
          validate_json_integrity(data)
        end

        it "can skip some configured nodes from including data" do
          resource = Restaurant.new
          resource.guests = [Guest.new(1), Guest.new(2)]

          ref_config = FastJSONAPISerializer::RelationshipConfig.parse({
              :guests => {:friends => [:friends]},
              :diners => [:diners],
              :vips   => [:vips],
            }
          )
          ref_config.children.not_nil!.find { |node| node.name == :guests }.not_nil!.embed(false)
          data = RestaurantSerializer.new(resource).serialize(includes: ref_config)

          data.should contain(%("included"))
          data.should contain(%("relationships"))
          # restaurant has_many :guests
          # -- > guest has_many :friends -> which happens to other guests
          # so we include all restaurant guests and the guests.friends(Guests)
          # which uniquely returns a list of 4 guests in the included
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12}" +
            ",\"relationships\":{\"guests\":{\"data\":[" +
            "{\"id\":\"1\",\"type\":\"guest\"}," +
            "{\"id\":\"2\",\"type\":\"guest\"}]}," +
            "\"diners\":{\"data\":[{\"id\":\"60\",\"type\":\"guest\"}]}," +
            "\"vips\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"}]}}}" +
            ",\"included\":[" +
            "{\"id\":\"1\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{\"friends\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"},{\"id\":\"3\",\"type\":\"guest\"}]}}}," +
            "{\"id\":\"60\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{}}]}"
          )
          validate_json_integrity(data)
        end

        it "ignores unknown includes" do
          resource = Restaurant.new
          data = RestaurantSerializer.new(resource).serialize(
            includes: {
              :some_rooms => [:some_rooms],
            },
          )
          data.should_not contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq("{\"data\":{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"name\":\"big burgers\",\"Rating\":\"Great!\",\"own_field\":12},\"relationships\":{}}}")
          validate_json_integrity(data)
        end
      end

      context "with kitchen sink" do
        it "works with all includes for single object" do
          resource = Restaurant.new
          resource.address = Address.new
          resource.post_code = PostCode.new
          resource.guests = [Guest.new(1), Guest.new(2)]
          room1 = Room.new(1)
          room1.tables = [Table.new(1), Table.new(2)]
          room2 = Room.new(2)
          resource.rooms = [room1, room2]
          data = RestaurantSerializer.new(resource).serialize(
            except: %i(name),
            includes: {
              :address   => [:address],
              :post_code => [:post_code],
              :rooms     => {:tables => [:tables]},
              :tables    => {:room => [:room]},
              :guests    => {:friends => [:friends]},
              :diners    => [:diners],
              :vips      => [:vips],
            },
            meta: {:page => 0, :limit => 50},
            options: {:test => true}
          )
          data.should_not contain(%("Rating"))
          data.should_not contain(%("name": "big burgers"))
          data.should contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":{\"id\":\"1\",\"type\":\"restaurant\"" +
            ",\"attributes\":{\"own_field\":\"custom-big burgers\"}," +
            "\"relationships\":{\"address\":{\"data\":{\"id\":\"101\",\"type\":\"address\"}}" +
            ",\"post_code\":{\"data\":{\"id\":\"101\",\"type\":\"post_code\"}}" +
            ",\"rooms\":{\"data\":[{\"id\":\"1\",\"type\":\"room\"},{\"id\":\"2\",\"type\":\"room\"}]}" +
            ",\"Tables\":{\"data\":[{\"id\":\"1\",\"type\":\"table\"},{\"id\":\"2\",\"type\":\"table\"},{\"id\":\"3\",\"type\":\"table\"}]}" +
            ",\"guests\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"}]}" +
            ",\"diners\":{\"data\":[{\"id\":\"60\",\"type\":\"guest\"}]},\"vips\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"}]}}}" +
            ",\"included\":[{\"id\":\"101\",\"type\":\"address\",\"attributes\":{\"street\":\"some street\"}}" +
            ",{\"id\":\"101\",\"type\":\"post_code\",\"attributes\":{\"code\":\"code 24\"}}" +
            ",{\"id\":\"1\",\"type\":\"table\",\"attributes\":{\"number\":1},\"relationships\":{}},{\"id\":\"2\",\"type\":\"table\",\"attributes\":{\"number\":2},\"relationships\":{}}" +
            ",{\"id\":\"1\",\"type\":\"room\",\"attributes\":{\"name\":\"1-name\"},\"relationships\":{\"tables\":{\"data\":[{\"id\":\"1\",\"type\":\"table\"},{\"id\":\"2\",\"type\":\"table\"}]}}}" +
            ",{\"id\":\"2\",\"type\":\"room\",\"attributes\":{\"name\":\"2-name\"},\"relationships\":{\"tables\":{\"data\":[]}}},{\"id\":\"3\",\"type\":\"room\",\"attributes\":{\"name\":\"3-name\"},\"relationships\":{}}" +
            ",{\"id\":\"3\",\"type\":\"table\",\"attributes\":{\"number\":3},\"relationships\":{\"room\":{\"data\":{\"id\":\"3\",\"type\":\"room\"}}}},{\"id\":\"3\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"}}" +
            ",{\"id\":\"2\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{\"friends\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"},{\"id\":\"3\",\"type\":\"guest\"}]}}}" +
            ",{\"id\":\"1\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{\"friends\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"},{\"id\":\"3\",\"type\":\"guest\"}]}}}" +
            ",{\"id\":\"60\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"},\"relationships\":{}}],\"meta\":{\"page\":0,\"limit\":50}}"
          )
          validate_json_integrity(data)
        end

        it "works with all includes for collection" do
          resource = Restaurant.new
          resource.address = Address.new
          resource.post_code = PostCode.new
          resource.guests = [Guest.new(1), Guest.new(2)]
          room1 = Room.new(1)
          room1.tables = [Table.new(1), Table.new(2)]
          room2 = Room.new(2)
          resource.rooms = [room1, room2]
          data = RestaurantSerializer.new([resource, resource]).serialize(
            except: %i(name),
            includes: {
              :address   => [:address],
              :post_code => [:post_code],
              :rooms     => {:tables => [:tables]},
              :tables    => {:room => [:room]},
              :guests    => {:friends => [:friends]},
              :diners    => [:diners],
              :vips      => [:vips],
            },
            meta: {:page => 0, :limit => 50},
            options: {:test => true}
          )
          data.should_not contain(%("Rating"))
          data.should_not contain(%("name": "big burgers"))
          data.should contain(%("included"))
          data.should contain(%("relationships"))
          data.should eq(
            "{\"data\":[{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"own_field\":\"custom-big burgers\"}" +
            ",\"relationships\":{\"address\":{\"data\":{\"id\":\"101\",\"type\":\"address\"}}" +
            ",\"post_code\":{\"data\":{\"id\":\"101\",\"type\":\"post_code\"}}" +
            ",\"rooms\":{\"data\":[{\"id\":\"1\",\"type\":\"room\"},{\"id\":\"2\",\"type\":\"room\"}]}" +
            ",\"Tables\":{\"data\":[{\"id\":\"1\",\"type\":\"table\"},{\"id\":\"2\",\"type\":\"table\"},{\"id\":\"3\",\"type\":\"table\"}]}" +
            ",\"guests\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"}]},\"diners\":{\"data\":[{\"id\":\"60\",\"type\":\"guest\"}]}" +
            ",\"vips\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"}]}}},{\"id\":\"1\",\"type\":\"restaurant\",\"attributes\":{\"own_field\":\"custom-big burgers\"},\"relationships\":{\"address\":{\"data\":{\"id\":\"101\",\"type\":\"address\"}}" +
            ",\"post_code\":{\"data\":{\"id\":\"101\",\"type\":\"post_code\"}},\"rooms\":{\"data\":[{\"id\":\"1\",\"type\":\"room\"},{\"id\":\"2\",\"type\":\"room\"}]}" +
            ",\"Tables\":{\"data\":[{\"id\":\"1\",\"type\":\"table\"},{\"id\":\"2\",\"type\":\"table\"},{\"id\":\"3\",\"type\":\"table\"}]}" +
            ",\"guests\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"}]},\"diners\":{\"data\":[{\"id\":\"60\",\"type\":\"guest\"}]}" +
            ",\"vips\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"}]}}}],\"included\":[{\"id\":\"101\",\"type\":\"address\",\"attributes\":{\"street\":\"some street\"}}" +
            ",{\"id\":\"101\",\"type\":\"post_code\",\"attributes\":{\"code\":\"code 24\"}},{\"id\":\"1\",\"type\":\"table\",\"attributes\":{\"number\":1},\"relationships\":{}}" +
            ",{\"id\":\"2\",\"type\":\"table\",\"attributes\":{\"number\":2},\"relationships\":{}},{\"id\":\"1\",\"type\":\"room\",\"attributes\":{\"name\":\"1-name\"}" +
            ",\"relationships\":{\"tables\":{\"data\":[{\"id\":\"1\",\"type\":\"table\"},{\"id\":\"2\",\"type\":\"table\"}]}}},{\"id\":\"2\",\"type\":\"room\",\"attributes\":{\"name\":\"2-name\"}" +
            ",\"relationships\":{\"tables\":{\"data\":[]}}},{\"id\":\"3\",\"type\":\"room\",\"attributes\":{\"name\":\"3-name\"},\"relationships\":{}},{\"id\":\"3\",\"type\":\"table\",\"attributes\":{\"number\":3}" +
            ",\"relationships\":{\"room\":{\"data\":{\"id\":\"3\",\"type\":\"room\"}}}},{\"id\":\"3\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"}},{\"id\":\"2\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"}" +
            ",\"relationships\":{\"friends\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"},{\"id\":\"3\",\"type\":\"guest\"}]}}},{\"id\":\"1\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"}" +
            ",\"relationships\":{\"friends\":{\"data\":[{\"id\":\"1\",\"type\":\"guest\"},{\"id\":\"2\",\"type\":\"guest\"},{\"id\":\"3\",\"type\":\"guest\"}]}}},{\"id\":\"60\",\"type\":\"guest\",\"attributes\":{\"age\":25,\"name\":\"Joe\"}" +
            ",\"relationships\":{}}],\"meta\":{\"page\":0,\"limit\":50}}"
          )
          validate_json_integrity(data)
        end
      end
    end
  end
end
