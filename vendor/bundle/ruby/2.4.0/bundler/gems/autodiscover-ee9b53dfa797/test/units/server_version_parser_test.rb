require "test_helper"

describe Autodiscover::ServerVersionParser do
  let(:_class) { Autodiscover::ServerVersionParser }

  it "parses a hex ServerVersion response" do
    inst = _class.new("738180DA")
    _(inst.major).must_equal 14
    _(inst.minor).must_equal 1
    _(inst.build).must_equal 218
  end

  it "returns an Exchange Server Version" do
    inst = _class.new("738180DA")
    inst.exchange_version.must_equal "Exchange2010_SP1"
  end

end
