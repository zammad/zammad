require "spec_helper"

describe Nori do

  Nori::PARSERS.each do |parser, class_name|
    context "using the :#{parser} parser" do

      let(:parser) { parser }

      it "should work with unnormalized characters" do
        xml = '<root>&amp;</root>'
        expect(parse(xml)).to eq({ 'root' => "&" })
      end

      it "should transform a simple tag with content" do
        xml = "<tag>This is the contents</tag>"
        expect(parse(xml)).to eq({ 'tag' => 'This is the contents' })
      end

      it "should work with cdata tags" do
        xml = <<-END
          <tag>
          <![CDATA[
            text inside cdata
          ]]>
          </tag>
        END
        expect(parse(xml)["tag"].strip).to eq("text inside cdata")
      end

      it "should transform a simple tag with attributes" do
        xml = "<tag attr1='1' attr2='2'></tag>"
        hash = { 'tag' => { '@attr1' => '1', '@attr2' => '2' } }
        expect(parse(xml)).to eq(hash)
      end

      it "should transform repeating siblings into an array" do
        xml =<<-XML
          <opt>
            <user login="grep" fullname="Gary R Epstein" />
            <user login="stty" fullname="Simon T Tyson" />
          </opt>
        XML

        expect(parse(xml)['opt']['user'].class).to eq(Array)

        hash = {
          'opt' => {
            'user' => [{
              '@login'    => 'grep',
              '@fullname' => 'Gary R Epstein'
            },{
              '@login'    => 'stty',
              '@fullname' => 'Simon T Tyson'
            }]
          }
        }

        expect(parse(xml)).to eq(hash)
      end

      it "should not transform non-repeating siblings into an array" do
        xml =<<-XML
          <opt>
            <user login="grep" fullname="Gary R Epstein" />
          </opt>
        XML

        expect(parse(xml)['opt']['user'].class).to eq(Hash)

        hash = {
          'opt' => {
            'user' => {
              '@login' => 'grep',
              '@fullname' => 'Gary R Epstein'
            }
          }
        }

        expect(parse(xml)).to eq(hash)
      end

      it "should prefix attributes with an @-sign to avoid problems with overwritten values" do
        xml =<<-XML
          <multiRef id="id1">
            <login>grep</login>
            <id>76737</id>
          </multiRef>
        XML

        expect(parse(xml)["multiRef"]).to eq({ "login" => "grep", "@id" => "id1", "id" => "76737" })
      end

      context "without advanced typecasting" do
        it "should not transform 'true'" do
          hash = parse("<value>true</value>", :advanced_typecasting => false)
          expect(hash["value"]).to eq("true")
        end

        it "should not transform 'false'" do
          hash = parse("<value>false</value>", :advanced_typecasting => false)
          expect(hash["value"]).to eq("false")
        end

        it "should not transform Strings matching the xs:time format" do
          hash = parse("<value>09:33:55Z</value>", :advanced_typecasting => false)
          expect(hash["value"]).to eq("09:33:55Z")
        end

        it "should not transform Strings matching the xs:date format" do
          hash = parse("<value>1955-04-18-05:00</value>", :advanced_typecasting => false)
          expect(hash["value"]).to eq("1955-04-18-05:00")
        end

        it "should not transform Strings matching the xs:dateTime format" do
          hash = parse("<value>1955-04-18T11:22:33-05:00</value>", :advanced_typecasting => false)
          expect(hash["value"]).to eq("1955-04-18T11:22:33-05:00")
        end
      end

      context "with advanced typecasting" do
        it "should transform 'true' to TrueClass" do
          expect(parse("<value>true</value>")["value"]).to eq(true)
        end

        it "should transform 'false' to FalseClass" do
          expect(parse("<value>false</value>")["value"]).to eq(false)
        end

        it "should transform Strings matching the xs:time format to Time objects" do
          expect(parse("<value>09:33:55.7Z</value>")["value"]).to eq(Time.parse("09:33:55.7Z"))
        end

        it "should transform Strings matching the xs:time format ahead of utc to Time objects" do
          expect(parse("<value>09:33:55+02:00</value>")["value"]).to eq(Time.parse("09:33:55+02:00"))
        end

        it "should transform Strings matching the xs:date format to Date objects" do
          expect(parse("<value>1955-04-18-05:00</value>")["value"]).to eq(Date.parse("1955-04-18-05:00"))
        end

        it "should transform Strings matching the xs:dateTime format ahead of utc to Date objects" do
          expect(parse("<value>1955-04-18+02:00</value>")["value"]).to eq(Date.parse("1955-04-18+02:00"))
        end

        it "should transform Strings matching the xs:dateTime format to DateTime objects" do
          expect(parse("<value>1955-04-18T11:22:33.5Z</value>")["value"]).to eq(
            DateTime.parse("1955-04-18T11:22:33.5Z")
          )
        end

        it "should transform Strings matching the xs:dateTime format ahead of utc to DateTime objects" do
          expect(parse("<value>1955-04-18T11:22:33+02:00</value>")["value"]).to eq(
            DateTime.parse("1955-04-18T11:22:33+02:00")
          )
        end

        it "should transform Strings matching the xs:dateTime format with seconds and an offset to DateTime objects" do
          expect(parse("<value>2004-04-12T13:20:15.5-05:00</value>")["value"]).to eq(
            DateTime.parse("2004-04-12T13:20:15.5-05:00")
          )
        end

        it "should not transform Strings containing an xs:time String and more" do
          expect(parse("<value>09:33:55Z is a time</value>")["value"]).to eq("09:33:55Z is a time")
          expect(parse("<value>09:33:55Z_is_a_file_name</value>")["value"]).to eq("09:33:55Z_is_a_file_name")
        end

        it "should not transform Strings containing an xs:date String and more" do
          expect(parse("<value>1955-04-18-05:00 is a date</value>")["value"]).to eq("1955-04-18-05:00 is a date")
          expect(parse("<value>1955-04-18-05:00_is_a_file_name</value>")["value"]).to eq("1955-04-18-05:00_is_a_file_name")
        end

        it "should not transform Strings containing an xs:dateTime String and more" do
          expect(parse("<value>1955-04-18T11:22:33-05:00 is a dateTime</value>")["value"]).to eq(
            "1955-04-18T11:22:33-05:00 is a dateTime"
          )
          expect(parse("<value>1955-04-18T11:22:33-05:00_is_a_file_name</value>")["value"]).to eq(
            "1955-04-18T11:22:33-05:00_is_a_file_name"
          )
        end

        ["00-00-00", "0000-00-00", "0000-00-00T00:00:00", "0569-23-0141", "DS2001-19-1312654773", "e6:53:01:00:ce:b4:06"].each do |date_string|
          it "should not transform a String like '#{date_string}' to date or time" do
            expect(parse("<value>#{date_string}</value>")["value"]).to eq(date_string)
          end
        end
      end

      context "Parsing xml with text and attributes" do
        before do
          xml =<<-XML
            <opt>
              <user login="grep">Gary R Epstein</user>
              <user>Simon T Tyson</user>
            </opt>
          XML
          @data = parse(xml)
        end

        it "correctly parse text nodes" do
          expect(@data).to eq({
            'opt' => {
              'user' => [
                'Gary R Epstein',
                'Simon T Tyson'
              ]
            }
          })
        end

        it "parses attributes for text node if present" do
          expect(@data['opt']['user'][0].attributes).to eq({'login' => 'grep'})
        end

        it "default attributes to empty hash if not present" do
          expect(@data['opt']['user'][1].attributes).to eq({})
        end

        it "add 'attributes' accessor methods to parsed instances of String" do
          expect(@data['opt']['user'][0]).to respond_to(:attributes)
          expect(@data['opt']['user'][0]).to respond_to(:attributes=)
        end

        it "not add 'attributes' accessor methods to all instances of String" do
          expect("some-string").not_to respond_to(:attributes)
          expect("some-string").not_to respond_to(:attributes=)
        end
      end

      it "should typecast an integer" do
        xml = "<tag type='integer'>10</tag>"
        expect(parse(xml)['tag']).to eq(10)
      end

      it "should typecast a true boolean" do
        xml = "<tag type='boolean'>true</tag>"
        expect(parse(xml)['tag']).to be(true)
      end

      it "should typecast a false boolean" do
        ["false"].each do |w|
          expect(parse("<tag type='boolean'>#{w}</tag>")['tag']).to be(false)
        end
      end

      it "should typecast a datetime" do
        xml = "<tag type='datetime'>2007-12-31 10:32</tag>"
        expect(parse(xml)['tag']).to eq(Time.parse( '2007-12-31 10:32' ).utc)
      end

      it "should typecast a date" do
        xml = "<tag type='date'>2007-12-31</tag>"
        expect(parse(xml)['tag']).to eq(Date.parse('2007-12-31'))
      end

      xml_entities = {
        "<" => "&lt;",
        ">" => "&gt;",
        '"' => "&quot;",
        "'" => "&apos;",
        "&" => "&amp;"
      }

      it "should unescape html entities" do
        xml_entities.each do |k,v|
          xml = "<tag>Some content #{v}</tag>"
          expect(parse(xml)['tag']).to match(Regexp.new(k))
        end
      end

      it "should unescape XML entities in attributes" do
        xml_entities.each do |key, value|
          xml = "<tag attr='Some content #{value}'></tag>"
          expect(parse(xml)['tag']['@attr']).to match(Regexp.new(key))
        end
      end

      it "should undasherize keys as tags" do
        xml = "<tag-1>Stuff</tag-1>"
        expect(parse(xml).keys).to include('tag_1')
      end

      it "should undasherize keys as attributes" do
        xml = "<tag1 attr-1='1'></tag1>"
        expect(parse(xml)['tag1'].keys).to include('@attr_1')
      end

      it "should undasherize keys as tags and attributes" do
        xml = "<tag-1 attr-1='1'></tag-1>"
        expect(parse(xml).keys).to include('tag_1')
        expect(parse(xml)['tag_1'].keys).to include('@attr_1')
      end

      it "should render nested content correctly" do
        xml = "<root><tag1>Tag1 Content <em><strong>This is strong</strong></em></tag1></root>"
        expect(parse(xml)['root']['tag1']).to eq("Tag1 Content <em><strong>This is strong</strong></em>")
      end

      it "should render nested content with text nodes correctly" do
        xml = "<root>Tag1 Content<em>Stuff</em> Hi There</root>"
        expect(parse(xml)['root']).to eq("Tag1 Content<em>Stuff</em> Hi There")
      end

      it "should ignore attributes when a child is a text node" do
        xml = "<root attr1='1'>Stuff</root>"
        expect(parse(xml)).to eq({ "root" => "Stuff" })
      end

      it "should ignore attributes when any child is a text node" do
        xml = "<root attr1='1'>Stuff <em>in italics</em></root>"
        expect(parse(xml)).to eq({ "root" => "Stuff <em>in italics</em>" })
      end

      it "should correctly transform multiple children" do
        xml = <<-XML
        <user gender='m'>
          <age type='integer'>35</age>
          <name>Home Simpson</name>
          <dob type='date'>1988-01-01</dob>
          <joined-at type='datetime'>2000-04-28 23:01</joined-at>
          <is-cool type='boolean'>true</is-cool>
        </user>
        XML

        hash = {
          "user" => {
            "@gender"   => "m",
            "age"       => 35,
            "name"      => "Home Simpson",
            "dob"       => Date.parse('1988-01-01'),
            "joined_at" => Time.parse("2000-04-28 23:01"),
            "is_cool"   => true
          }
        }

        expect(parse(xml)).to eq(hash)
      end

      it "should properly handle nil values (ActiveSupport Compatible)" do
        topic_xml = <<-EOT
          <topic>
            <title></title>
            <id type="integer"></id>
            <approved type="boolean"></approved>
            <written-on type="date"></written-on>
            <viewed-at type="datetime"></viewed-at>
            <content type="yaml"></content>
            <parent-id></parent-id>
            <nil_true nil="true"/>
            <namespaced xsi:nil="true" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"/>
          </topic>
        EOT

        expected_topic_hash = {
          'title'      => nil,
          'id'         => nil,
          'approved'   => nil,
          'written_on' => nil,
          'viewed_at'  => nil,
          # don't execute arbitary YAML code
          'content'    => { "@type" => "yaml" },
          'parent_id'  => nil,
          'nil_true'   => nil,
          'namespaced' => nil
        }
        expect(parse(topic_xml)["topic"]).to eq(expected_topic_hash)
      end

      it "should handle a single record from xml (ActiveSupport Compatible)" do
        topic_xml = <<-EOT
          <topic>
            <title>The First Topic</title>
            <author-name>David</author-name>
            <id type="integer">1</id>
            <approved type="boolean"> true </approved>
            <replies-count type="integer">0</replies-count>
            <replies-close-in type="integer">2592000000</replies-close-in>
            <written-on type="date">2003-07-16</written-on>
            <viewed-at type="datetime">2003-07-16T09:28:00+0000</viewed-at>
            <content type="yaml">--- \n1: should be an integer\n:message: Have a nice day\narray: \n- should-have-dashes: true\n  should_have_underscores: true</content>
            <author-email-address>david@loudthinking.com</author-email-address>
            <parent-id></parent-id>
            <ad-revenue type="decimal">1.5</ad-revenue>
            <optimum-viewing-angle type="float">135</optimum-viewing-angle>
            <resident type="symbol">yes</resident>
          </topic>
        EOT

        expected_topic_hash = {
          'title' => "The First Topic",
          'author_name' => "David",
          'id' => 1,
          'approved' => true,
          'replies_count' => 0,
          'replies_close_in' => 2592000000,
          'written_on' => Date.new(2003, 7, 16),
          'viewed_at' => Time.utc(2003, 7, 16, 9, 28),
          # Changed this line where the key is :message.  The yaml specifies this as a symbol, and who am I to change what you specify
          # The line in ActiveSupport is
          # 'content' => { 'message' => "Have a nice day", 1 => "should be an integer", "array" => [{ "should-have-dashes" => true, "should_have_underscores" => true }] },
          'content' => "--- \n1: should be an integer\n:message: Have a nice day\narray: \n- should-have-dashes: true\n  should_have_underscores: true",
          'author_email_address' => "david@loudthinking.com",
          'parent_id' => nil,
          'ad_revenue' => BigDecimal("1.50"),
          'optimum_viewing_angle' => 135.0,
          # don't create symbols from arbitary remote code
          'resident' => "yes"
        }

        parse(topic_xml)["topic"].each do |k,v|
          expect(v).to eq(expected_topic_hash[k])
        end
      end

      it "should handle multiple records (ActiveSupport Compatible)" do
        topics_xml = <<-EOT
          <topics type="array">
            <topic>
              <title>The First Topic</title>
              <author-name>David</author-name>
              <id type="integer">1</id>
              <approved type="boolean">false</approved>
              <replies-count type="integer">0</replies-count>
              <replies-close-in type="integer">2592000000</replies-close-in>
              <written-on type="date">2003-07-16</written-on>
              <viewed-at type="datetime">2003-07-16T09:28:00+0000</viewed-at>
              <content>Have a nice day</content>
              <author-email-address>david@loudthinking.com</author-email-address>
              <parent-id nil="true"></parent-id>
            </topic>
            <topic>
              <title>The Second Topic</title>
              <author-name>Jason</author-name>
              <id type="integer">1</id>
              <approved type="boolean">false</approved>
              <replies-count type="integer">0</replies-count>
              <replies-close-in type="integer">2592000000</replies-close-in>
              <written-on type="date">2003-07-16</written-on>
              <viewed-at type="datetime">2003-07-16T09:28:00+0000</viewed-at>
              <content>Have a nice day</content>
              <author-email-address>david@loudthinking.com</author-email-address>
              <parent-id></parent-id>
            </topic>
          </topics>
        EOT

        expected_topic_hash = {
          'title' => "The First Topic",
          'author_name' => "David",
          'id' => 1,
          'approved' => false,
          'replies_count' => 0,
          'replies_close_in' => 2592000000,
          'written_on' => Date.new(2003, 7, 16),
          'viewed_at' => Time.utc(2003, 7, 16, 9, 28),
          'content' => "Have a nice day",
          'author_email_address' => "david@loudthinking.com",
          'parent_id' => nil
        }

        # puts Nori.parse(topics_xml)['topics'].first.inspect
        parse(topics_xml)["topics"].first.each do |k,v|
          expect(v).to eq(expected_topic_hash[k])
        end
      end

      context "with convert_attributes_to set to a custom formula" do
        it "alters attributes and values" do
          converter = lambda {|key, value| ["#{key}_k", "#{value}_v"] }
          xml = <<-XML
            <user name="value"><age>21</age></user>
          XML

          expect(parse(xml, :convert_attributes_to => converter)).to eq({'user' => {'@name_k' => 'value_v', 'age' => '21'}})
        end
      end

      it "should handle a single record from_xml with attributes other than type (ActiveSupport Compatible)" do
        topic_xml = <<-EOT
        <rsp stat="ok">
          <photos page="1" pages="1" perpage="100" total="16">
            <photo id="175756086" owner="55569174@N00" secret="0279bf37a1" server="76" title="Colored Pencil PhotoBooth Fun" ispublic="1" isfriend="0" isfamily="0"/>
          </photos>
        </rsp>
        EOT

        expected_topic_hash = {
          '@id' => "175756086",
          '@owner' => "55569174@N00",
          '@secret' => "0279bf37a1",
          '@server' => "76",
          '@title' => "Colored Pencil PhotoBooth Fun",
          '@ispublic' => "1",
          '@isfriend' => "0",
          '@isfamily' => "0",
        }

        parse(topic_xml)["rsp"]["photos"]["photo"].each do |k, v|
          expect(v).to eq(expected_topic_hash[k])
        end
      end

      it "should handle an emtpy array (ActiveSupport Compatible)" do
        blog_xml = <<-XML
          <blog>
            <posts type="array"></posts>
          </blog>
        XML
        expected_blog_hash = {"blog" => {"posts" => []}}
        expect(parse(blog_xml)).to eq(expected_blog_hash)
      end

      it "should handle empty array with whitespace from xml (ActiveSupport Compatible)" do
        blog_xml = <<-XML
          <blog>
            <posts type="array">
            </posts>
          </blog>
        XML
        expected_blog_hash = {"blog" => {"posts" => []}}
        expect(parse(blog_xml)).to eq(expected_blog_hash)
      end

      it "should handle array with one entry from_xml (ActiveSupport Compatible)" do
        blog_xml = <<-XML
          <blog>
            <posts type="array">
              <post>a post</post>
            </posts>
          </blog>
        XML
        expected_blog_hash = {"blog" => {"posts" => ["a post"]}}
        expect(parse(blog_xml)).to eq(expected_blog_hash)
      end

      it "should handle array with multiple entries from xml (ActiveSupport Compatible)" do
        blog_xml = <<-XML
          <blog>
            <posts type="array">
              <post>a post</post>
              <post>another post</post>
            </posts>
          </blog>
        XML
        expected_blog_hash = {"blog" => {"posts" => ["a post", "another post"]}}
        expect(parse(blog_xml)).to eq(expected_blog_hash)
      end

      it "should handle file types (ActiveSupport Compatible)" do
        blog_xml = <<-XML
          <blog>
            <logo type="file" name="logo.png" content_type="image/png">
            </logo>
          </blog>
        XML
        hash = parse(blog_xml)
        expect(hash.keys).to include('blog')
        expect(hash['blog'].keys).to include('logo')

        file = hash['blog']['logo']
        expect(file.original_filename).to eq('logo.png')
        expect(file.content_type).to eq('image/png')
      end

      it "should handle file from xml with defaults (ActiveSupport Compatible)" do
        blog_xml = <<-XML
          <blog>
            <logo type="file">
            </logo>
          </blog>
        XML
        file = parse(blog_xml)['blog']['logo']
        expect(file.original_filename).to eq('untitled')
        expect(file.content_type).to eq('application/octet-stream')
      end

      it "should handle xsd like types from xml (ActiveSupport Compatible)" do
        bacon_xml = <<-EOT
        <bacon>
          <weight type="double">0.5</weight>
          <price type="decimal">12.50</price>
          <chunky type="boolean"> 1 </chunky>
          <expires-at type="dateTime">2007-12-25T12:34:56+0000</expires-at>
          <notes type="string"></notes>
          <illustration type="base64Binary">YmFiZS5wbmc=</illustration>
        </bacon>
        EOT

        expected_bacon_hash = {
          'weight' => 0.5,
          'chunky' => true,
          'price' => BigDecimal("12.50"),
          'expires_at' => Time.utc(2007,12,25,12,34,56),
          'notes' => "",
          'illustration' => "babe.png"
        }

        expect(parse(bacon_xml)["bacon"]).to eq(expected_bacon_hash)
      end

      it "should let type trickle through when unknown (ActiveSupport Compatible)" do
        product_xml = <<-EOT
        <product>
          <weight type="double">0.5</weight>
          <image type="ProductImage"><filename>image.gif</filename></image>

        </product>
        EOT

        expected_product_hash = {
          'weight' => 0.5,
          'image' => {'@type' => 'ProductImage', 'filename' => 'image.gif' },
        }

        expect(parse(product_xml)["product"]).to eq(expected_product_hash)
      end

      it "should handle unescaping from xml (ActiveResource Compatible)" do
       xml_string = '<person><bare-string>First &amp; Last Name</bare-string><pre-escaped-string>First &amp;amp; Last Name</pre-escaped-string></person>'
       expected_hash = {
         'bare_string'        => 'First & Last Name',
         'pre_escaped_string' => 'First &amp; Last Name'
       }

       expect(parse(xml_string)['person']).to eq(expected_hash)
     end

      it "handle an empty xml string" do
        expect(parse('')).to eq({})
      end

      # As returned in the response body by the unfuddle XML API when creating objects
      it "handle an xml string containing a single space" do
        expect(parse(' ')).to eq({})
      end

    end
  end

  def parse(xml, options = {})
    defaults = {:parser => parser}
    Nori.new(defaults.merge(options)).parse(xml)
  end
end
