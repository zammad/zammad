require "spec_helper"

describe Nori do

  describe "PARSERS" do
    it "should return a Hash of parser details" do
      expect(Nori::PARSERS).to eq({ :rexml => "REXML", :nokogiri => "Nokogiri" })
    end
  end

  context ".new" do
    it "defaults to not strip any namespace identifiers" do
      xml = <<-XML
        <history xmlns:ns10="http://ns10.example.com">
          <ns10:case>a_case</ns10:case>
        </history>
      XML

      expect(nori.parse(xml)["history"]["ns10:case"]).to eq("a_case")
    end

    it "defaults to not change XML tags" do
      xml = '<userResponse id="1"><accountStatus>active</accountStatus></userResponse>'
      expect(nori.parse(xml)).to eq({ "userResponse" => { "@id" => "1", "accountStatus" => "active" } })
    end

    it "raises when passed unknown global options" do
      expect { Nori.new(:invalid => true) }.
        to raise_error(ArgumentError, /Spurious options: \[:invalid\]/)
    end
  end

  context ".new with :strip_namespaces" do
    it "strips the namespace identifiers when set to true" do
      xml = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"></soap:Envelope>'
      expect(nori(:strip_namespaces => true).parse(xml)).to have_key("Envelope")
    end

    it "still converts namespaced entries to array elements" do
      xml = <<-XML
        <history
            xmlns:ns10="http://ns10.example.com"
            xmlns:ns11="http://ns10.example.com">
          <ns10:case><ns10:name>a_name</ns10:name></ns10:case>
          <ns11:case><ns11:name>another_name</ns11:name></ns11:case>
        </history>
      XML

      expected = [{ "name" => "a_name" }, { "name" => "another_name" }]
      expect(nori(:strip_namespaces => true).parse(xml)["history"]["case"]).to eq(expected)
    end
  end

  context ".new with :convert_tags_to" do
    it "converts all tags by a given formula" do
      xml = '<userResponse id="1"><accountStatus>active</accountStatus></userResponse>'

      snakecase_symbols = lambda { |tag| tag.snakecase.to_sym }
      nori = nori(:convert_tags_to => snakecase_symbols)

      expect(nori.parse(xml)).to eq({ :user_response => { :@id => "1", :account_status => "active" } })
    end
  end

	context '#find' do
		before do
      upcase = lambda { |tag| tag.upcase }
			@nori = nori(:convert_tags_to => upcase)

      xml = '<userResponse id="1"><accountStatus>active</accountStatus></userResponse>'
			@hash = @nori.parse(xml)
		end

		it 'returns the Hash when the path is empty' do
			result = @nori.find(@hash)
			expect(result).to eq("USERRESPONSE" => { "ACCOUNTSTATUS" => "active", "@ID" => "1" })
		end

		it 'returns the result for a single key' do
			result = @nori.find(@hash, 'userResponse')
			expect(result).to eq("ACCOUNTSTATUS" => "active", "@ID" => "1")
		end

		it 'returns the result for nested keys' do
			result = @nori.find(@hash, 'userResponse', 'accountStatus')
			expect(result).to eq("active")
		end

		it 'strips the namespaces from Hash keys' do
			xml = '<v1:userResponse xmlns:v1="http://example.com"><v1:accountStatus>active</v1:accountStatus></v1:userResponse>'
			hash = @nori.parse(xml)

			result = @nori.find(hash, 'userResponse', 'accountStatus')
			expect(result).to eq("active")
		end
	end

  context "#parse" do
    it "defaults to use advanced typecasting" do
      hash = nori.parse("<value>true</value>")
      expect(hash["value"]).to eq(true)
    end

    it "defaults to use the Nokogiri parser" do
      # parsers are loaded lazily by default
      require "nori/parser/nokogiri"

      expect(Nori::Parser::Nokogiri).to receive(:parse).and_return({})
      nori.parse("<any>thing</any>")
    end

    it "strips the XML" do
      xml = double("xml")
      expect(xml).to receive(:strip).and_return("<any>thing</any>")

      expect(nori.parse(xml)).to eq({ "any" => "thing" })
    end
  end

  context "#parse without :advanced_typecasting" do
    it "can be changed to not typecast too much" do
      hash = nori(:advanced_typecasting => false).parse("<value>true</value>")
      expect(hash["value"]).to eq("true")
    end
  end

  context "#parse with :parser" do
    it "can be configured to use the REXML parser" do
      # parsers are loaded lazily by default
      require "nori/parser/rexml"

      expect(Nori::Parser::REXML).to receive(:parse).and_return({})
      nori(:parser => :rexml).parse("<any>thing</any>")
    end
  end

  context "#parse without :delete_namespace_attributes" do
    it "can be changed to not delete xmlns attributes" do
      xml = '<userResponse xmlns="http://schema.company.com/some/path/to/namespace/v1"><accountStatus>active</accountStatus></userResponse>'
      hash = nori(:delete_namespace_attributes => false).parse(xml)
      expect(hash).to eq({"userResponse" => {"@xmlns" => "http://schema.company.com/some/path/to/namespace/v1", "accountStatus" => "active"}})
    end

    it "can be changed to not delete xsi attributes" do
      xml = '<userResponse xsi="abc:myType"><accountStatus>active</accountStatus></userResponse>'
      hash = nori(:delete_namespace_attributes => false).parse(xml)
      expect(hash).to eq({"userResponse" => {"@xsi" => "abc:myType", "accountStatus" => "active"}})
    end
  end

  context "#parse with :delete_namespace_attributes" do
    it "can be changed to delete xmlns attributes" do
      xml = '<userResponse xmlns="http://schema.company.com/some/path/to/namespace/v1"><accountStatus>active</accountStatus></userResponse>'
      hash = nori(:delete_namespace_attributes => true).parse(xml)
      expect(hash).to eq({"userResponse" => {"accountStatus" => "active"}})
    end

    it "can be changed to delete xsi attributes" do
      xml = '<userResponse xsi="abc:myType"><accountStatus>active</accountStatus></userResponse>'
      hash = nori(:delete_namespace_attributes => true).parse(xml)
      expect(hash).to eq({"userResponse" => {"accountStatus" => "active"}})
    end
  end

  context "#parse with :convert_dashes_to_underscores" do
    it "can be configured to skip dash to underscope conversion" do
      xml = '<any-tag>foo bar</any-tag'
      hash = nori(:convert_dashes_to_underscores => false).parse(xml)
      expect(hash).to eq({'any-tag' => 'foo bar'})
    end
  end

  context "#parse with :empty_tag_value set to empty string" do
    it "can be configured to convert empty tags to given value" do
      xml = "<parentTag><tag/></parentTag>"
      hash = nori(:empty_tag_value => "").parse(xml)
      expect(hash).to eq("parentTag" => { "tag" => "" })
    end
  end

  def nori(options = {})
    Nori.new(options)
  end
end
