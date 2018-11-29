require "test_helper"

describe Autodiscover::Client do
  let(:_class) { Autodiscover::Client }

  describe "#initialize" do
     it "sets a username and domain from the email" do
      inst = _class.new(email: "test@example.local", password: "test")
      _(inst.domain).must_equal "example.local"
      _(inst.instance_variable_get(:@username)).must_equal "test@example.local"
    end

   it "allows you to override the username and domain" do
     inst = _class.new(email: "test@example.local", password: "test", username: 'DOMAIN\test', domain: "otherexample.local")
      _(inst.domain).must_equal "otherexample.local"
      _(inst.instance_variable_get(:@username)).must_equal 'DOMAIN\test'
    end
  end

  describe "#autodiscover" do
    it "dispatches autodiscover to a PoxRequest instance" do
      inst = _class.new(email: "test@example.local", password: "test")
      pox_request = mock("pox")
      pox_request.expects(:autodiscover)
      Autodiscover::PoxRequest.expects(:new).with(inst,{}).returns(pox_request)
      inst.autodiscover
    end

    it "raises an exception if an invalid autodiscover type is passed" do
      inst = _class.new(email: "test@example.local", password: "test")
      ->{ inst.autodiscover(type: :invalid) }.must_raise(Autodiscover::ArgumentError)
    end
  end

end
