require "test_helper"

describe Autodiscover::PoxResponse do
  let(:_class) {Autodiscover::PoxResponse }
  let(:response) { load_sample("pox_response.xml") }

  describe "#initialize" do
    it "parses an XML string into a Hash when initialized" do
      inst = _class.new response
      _(inst.response).must_be_instance_of Hash
    end

    it "it raises an exception if the response is empty or nil" do
      ->{_class.new ""}.must_raise(Autodiscover::ArgumentError)
      ->{_class.new nil}.must_raise(Autodiscover::ArgumentError)
    end
  end

  describe "#exchange_version" do
    it "returns an Exchange version usable for EWS" do
      _(_class.new(response).exchange_version).must_equal "Exchange2013_SP1"
    end
  end

  describe "#ews_url" do
    it "returns the EWS url" do
      _(_class.new(response).ews_url).must_equal "https://outlook.office365.com/EWS/Exchange.asmx"
    end
  end

  describe "Protocol Hashes" do
    let(:_inst) { _class.new(response) }

    it "returns the EXCH protocol Hash" do
      _(_inst.exch_proto["Type"]).must_equal "EXCH"
    end

    it "returns the EXPR protocol Hash" do
      _(_inst.expr_proto["Type"]).must_equal "EXPR"
    end

    it "returns the WEB protocol Hash" do
      _(_inst.web_proto["Type"]).must_equal "WEB"
    end

    it "returns empty Hashes when the protocols are missing" do
      _inst.response["Account"]["Protocol"] = []
      _(_inst.exch_proto).must_equal({})
      _(_inst.expr_proto).must_equal({})
      _(_inst.web_proto).must_equal({})
    end
  end

end
