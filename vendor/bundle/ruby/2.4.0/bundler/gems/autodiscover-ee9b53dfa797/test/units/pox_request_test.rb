require "test_helper"
require "ostruct"

describe Autodiscover::PoxRequest do
  let(:_class) {Autodiscover::PoxRequest }
  let(:http) { mock("http") }
  let(:client) { OpenStruct.new({http: http, domain: "example.local", email: "test@example.local"}) }

  describe "#autodiscover" do
    it "returns a PoxResponse if the autodiscover is successful" do
      request_body = <<-EOF.gsub(/^        /,"")
        <?xml version="1.0"?>
        <Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/requestschema/2006">
          <Request>
            <EMailAddress>test@example.local</EMailAddress>
            <AcceptableResponseSchema>http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a</AcceptableResponseSchema>
          </Request>
        </Autodiscover>
      EOF
      http.expects(:post).with(
        "https://example.local/autodiscover/autodiscover.xml", request_body,
        {'Content-Type' => 'text/xml; charset=utf-8'}
      ).returns(OpenStruct.new({status: 200, body: "<Autodiscover><Response><test></test></Response></Autodiscover>"}))

      inst = _class.new(client)
      _(inst.autodiscover).must_be_instance_of(Autodiscover::PoxResponse)
    end

    it "will fail if :ignore_ssl_errors is not true" do
      http.expects(:post).raises(OpenSSL::SSL::SSLError, "Test Error")
      inst = _class.new(client)
      -> {inst.autodiscover}.must_raise(OpenSSL::SSL::SSLError)
    end

    it "keeps trying if :ignore_ssl_errors is set" do
      http.expects(:get).once.returns(OpenStruct.new({headers: {"Location" => "http://example.local"}, status: 302}))
      http.expects(:post).times(3).
        raises(OpenSSL::SSL::SSLError, "Test Error").then.
        raises(OpenSSL::SSL::SSLError, "Test Error").then.
        raises(Errno::ENETUNREACH, "Test Error")
      inst = _class.new(client, ignore_ssl_errors: true)
      _(inst.autodiscover).must_be_nil
    end

  end
end
