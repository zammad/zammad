require 'spec_helper'

describe RestClient::Request do
  before do
    @request = RestClient::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload')

    @uri = double("uri")
    @uri.stub(:request_uri).and_return('/resource')
    @uri.stub(:host).and_return('some')
    @uri.stub(:port).and_return(80)

    @net = double("net::http base")
    @http = double("net::http connection")
    Net::HTTP.stub(:new).and_return(@net)
    @net.stub(:start).and_yield(@http)
    @net.stub(:use_ssl=)
    @net.stub(:verify_mode=)
    @net.stub(:verify_callback=)
    allow(@net).to receive(:ciphers=)
    allow(@net).to receive(:cert_store=)
    RestClient.log = nil
  end

  it "accept */* mimetype, preferring xml" do
    @request.default_headers[:accept].should eq '*/*; q=0.5, application/xml'
  end

  describe "compression" do

    it "decodes an uncompressed result body by passing it straight through" do
      RestClient::Request.decode(nil, 'xyz').should eq 'xyz'
    end

    it "doesn't fail for nil bodies" do
      RestClient::Request.decode('gzip', nil).should be_nil
    end


    it "decodes a gzip body" do
      RestClient::Request.decode('gzip', "\037\213\b\b\006'\252H\000\003t\000\313T\317UH\257\312,HM\341\002\000G\242(\r\v\000\000\000").should eq "i'm gziped\n"
    end

    it "ingores gzip for empty bodies" do
      RestClient::Request.decode('gzip', '').should be_empty
    end

    it "decodes a deflated body" do
      RestClient::Request.decode('deflate', "x\234+\316\317MUHIM\313I,IMQ(I\255(\001\000A\223\006\363").should eq "some deflated text"
    end
  end

  it "processes a successful result" do
    res = double("result")
    res.stub(:code).and_return("200")
    res.stub(:body).and_return('body')
    res.stub(:[]).with('content-encoding').and_return(nil)
    @request.process_result(res).body.should eq 'body'
    @request.process_result(res).to_s.should eq 'body'
  end

  it "doesn't classify successful requests as failed" do
    203.upto(207) do |code|
      res = double("result")
      res.stub(:code).and_return(code.to_s)
      res.stub(:body).and_return("")
      res.stub(:[]).with('content-encoding').and_return(nil)
      @request.process_result(res).should be_empty
    end
  end

  it "parses a url into a URI object" do
    URI.should_receive(:parse).with('http://example.com/resource')
    @request.parse_url('http://example.com/resource')
  end

  it "adds http:// to the front of resources specified in the syntax example.com/resource" do
    URI.should_receive(:parse).with('http://example.com/resource')
    @request.parse_url('example.com/resource')
  end

  describe "user - password" do
    it "extracts the username and password when parsing http://user:password@example.com/" do
      URI.stub(:parse).and_return(double('uri', :user => 'joe', :password => 'pass1'))
      @request.parse_url_with_auth('http://joe:pass1@example.com/resource')
      @request.user.should eq 'joe'
      @request.password.should eq 'pass1'
    end

    it "extracts with escaping the username and password when parsing http://user:password@example.com/" do
      URI.stub(:parse).and_return(double('uri', :user => 'joe%20', :password => 'pass1'))
      @request.parse_url_with_auth('http://joe%20:pass1@example.com/resource')
      @request.user.should eq 'joe '
      @request.password.should eq 'pass1'
    end

    it "doesn't overwrite user and password (which may have already been set by the Resource constructor) if there is no user/password in the url" do
      URI.stub(:parse).and_return(double('uri', :user => nil, :password => nil))
      @request = RestClient::Request.new(:method => 'get', :url => 'example.com', :user => 'beth', :password => 'pass2')
      @request.parse_url_with_auth('http://example.com/resource')
      @request.user.should eq 'beth'
      @request.password.should eq 'pass2'
    end
  end

  it "correctly formats cookies provided to the constructor" do
    URI.stub(:parse).and_return(double('uri', :user => nil, :password => nil))
    @request = RestClient::Request.new(:method => 'get', :url => 'example.com', :cookies => {:session_id => '1', :user_id => "someone" })
    @request.should_receive(:default_headers).and_return({'Foo' => 'bar'})
    @request.make_headers({}).should eq({ 'Foo' => 'bar', 'Cookie' => 'session_id=1; user_id=someone'})
  end

  it "does not escape or unescape cookies" do
    cookie = 'Foo%20:Bar%0A~'
    @request = RestClient::Request.new(:method => 'get', :url => 'example.com',
                                       :cookies => {:test => cookie})
    @request.should_receive(:default_headers).and_return({'Foo' => 'bar'})
    @request.make_headers({}).should eq({
      'Foo' => 'bar',
      'Cookie' => "test=#{cookie}"
    })
  end

  it "rejects cookie names containing invalid characters" do
    # Cookie validity is something of a mess, but we should reject the worst of
    # the RFC 6265 (4.1.1) prohibited characters such as control characters.

    ['', 'foo=bar', 'foo;bar', "foo\nbar"].each do |cookie_name|
      lambda {
        RestClient::Request.new(:method => 'get', :url => 'example.com',
                                :cookies => {cookie_name => 'value'})
      }.should raise_error(ArgumentError, /\AInvalid cookie name/)
    end
  end

  it "rejects cookie values containing invalid characters" do
    # Cookie validity is something of a mess, but we should reject the worst of
    # the RFC 6265 (4.1.1) prohibited characters such as control characters.

    ['foo,bar', 'foo;bar', "foo\nbar"].each do |cookie_value|
      lambda {
        RestClient::Request.new(:method => 'get', :url => 'example.com',
                                :cookies => {'test' => cookie_value})
      }.should raise_error(ArgumentError, /\AInvalid cookie value/)
    end
  end

  it "uses netrc credentials" do
    URI.stub(:parse).and_return(double('uri', :user => nil, :password => nil, :host => 'example.com'))
    Netrc.stub(:read).and_return('example.com' => ['a', 'b'])
    @request.parse_url_with_auth('http://example.com/resource')
    @request.user.should eq 'a'
    @request.password.should eq 'b'
  end

  it "uses credentials in the url in preference to netrc" do
    URI.stub(:parse).and_return(double('uri', :user => 'joe%20', :password => 'pass1', :host => 'example.com'))
    Netrc.stub(:read).and_return('example.com' => ['a', 'b'])
    @request.parse_url_with_auth('http://joe%20:pass1@example.com/resource')
    @request.user.should eq 'joe '
    @request.password.should eq 'pass1'
  end

  it "determines the Net::HTTP class to instantiate by the method name" do
    @request.net_http_request_class(:put).should eq Net::HTTP::Put
  end

  describe "user headers" do
    it "merges user headers with the default headers" do
      @request.should_receive(:default_headers).and_return({ :accept => '*/*; q=0.5, application/xml', :accept_encoding => 'gzip, deflate' })
      headers = @request.make_headers("Accept" => "application/json", :accept_encoding => 'gzip')
      headers.should have_key "Accept-Encoding"
      headers["Accept-Encoding"].should eq "gzip"
      headers.should have_key "Accept"
      headers["Accept"].should eq "application/json"
    end

    it "prefers the user header when the same header exists in the defaults" do
      @request.should_receive(:default_headers).and_return({ '1' => '2' })
      headers = @request.make_headers('1' => '3')
      headers.should have_key('1')
      headers['1'].should eq '3'
    end

    it "converts user headers to string before calling CGI::unescape which fails on non string values" do
      @request.should_receive(:default_headers).and_return({ '1' => '2' })
      headers = @request.make_headers('1' => 3)
      headers.should have_key('1')
      headers['1'].should eq '3'
    end
  end

  describe "header symbols" do

    it "converts header symbols from :content_type to 'Content-Type'" do
      @request.should_receive(:default_headers).and_return({})
      headers = @request.make_headers(:content_type => 'abc')
      headers.should have_key('Content-Type')
      headers['Content-Type'].should eq 'abc'
    end

    it "converts content-type from extension to real content-type" do
      @request.should_receive(:default_headers).and_return({})
      headers = @request.make_headers(:content_type => 'json')
      headers.should have_key('Content-Type')
      headers['Content-Type'].should eq 'application/json'
    end

    it "converts accept from extension(s) to real content-type(s)" do
      @request.should_receive(:default_headers).and_return({})
      headers = @request.make_headers(:accept => 'json, mp3')
      headers.should have_key('Accept')
      headers['Accept'].should eq 'application/json, audio/mpeg'

      @request.should_receive(:default_headers).and_return({})
      headers = @request.make_headers(:accept => :json)
      headers.should have_key('Accept')
      headers['Accept'].should eq 'application/json'
    end

    it "only convert symbols in header" do
      @request.should_receive(:default_headers).and_return({})
      headers = @request.make_headers({:foo_bar => 'value', "bar_bar" => 'value'})
      headers['Foo-Bar'].should eq 'value'
      headers['bar_bar'].should eq 'value'
    end

    it "converts header values to strings" do
      @request.make_headers('A' => 1)['A'].should eq '1'
    end
  end

  it "executes by constructing the Net::HTTP object, headers, and payload and calling transmit" do
    @request.should_receive(:parse_url_with_auth).with('http://some/resource').and_return(@uri)
    klass = double("net:http class")
    @request.should_receive(:net_http_request_class).with(:put).and_return(klass)
    klass.should_receive(:new).and_return('result')
    @request.should_receive(:transmit).with(@uri, 'result', kind_of(RestClient::Payload::Base))
    @request.execute
  end

  it "transmits the request with Net::HTTP" do
    @http.should_receive(:request).with('req', 'payload')
    @request.should_receive(:process_result)
    @request.transmit(@uri, 'req', 'payload')
  end

  describe "payload" do
    it "sends nil payloads" do
      @http.should_receive(:request).with('req', nil)
      @request.should_receive(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', nil)
    end

    it "passes non-hash payloads straight through" do
      @request.process_payload("x").should eq "x"
    end

    it "converts a hash payload to urlencoded data" do
      @request.process_payload(:a => 'b c+d').should eq "a=b%20c%2Bd"
    end

    it "accepts nested hashes in payload" do
      payload = @request.process_payload(:user => { :name => 'joe', :location => { :country => 'USA', :state => 'CA' }})
      payload.should include('user[name]=joe')
      payload.should include('user[location][country]=USA')
      payload.should include('user[location][state]=CA')
    end
  end

  it "set urlencoded content_type header on hash payloads" do
    @request.process_payload(:a => 1)
    @request.headers[:content_type].should eq 'application/x-www-form-urlencoded'
  end

  describe "credentials" do
    it "sets up the credentials prior to the request" do
      @http.stub(:request)

      @request.stub(:process_result)
      @request.stub(:response_log)

      @request.stub(:user).and_return('joe')
      @request.stub(:password).and_return('mypass')
      @request.should_receive(:setup_credentials).with('req')

      @request.transmit(@uri, 'req', nil)
    end

    it "does not attempt to send any credentials if user is nil" do
      @request.stub(:user).and_return(nil)
      req = double("request")
      req.should_not_receive(:basic_auth)
      @request.setup_credentials(req)
    end

    it "setup credentials when there's a user" do
      @request.stub(:user).and_return('joe')
      @request.stub(:password).and_return('mypass')
      req = double("request")
      req.should_receive(:basic_auth).with('joe', 'mypass')
      @request.setup_credentials(req)
    end
  end

  it "catches EOFError and shows the more informative ServerBrokeConnection" do
    @http.stub(:request).and_raise(EOFError)
    lambda { @request.transmit(@uri, 'req', nil) }.should raise_error(RestClient::ServerBrokeConnection)
  end

  it "catches OpenSSL::SSL::SSLError and raise it back without more informative message" do
    @http.stub(:request).and_raise(OpenSSL::SSL::SSLError)
    lambda { @request.transmit(@uri, 'req', nil) }.should raise_error(OpenSSL::SSL::SSLError)
  end

  it "catches Timeout::Error and raise the more informative RequestTimeout" do
    @http.stub(:request).and_raise(Timeout::Error)
    lambda { @request.transmit(@uri, 'req', nil) }.should raise_error(RestClient::RequestTimeout)
  end

  it "catches Timeout::Error and raise the more informative RequestTimeout" do
    @http.stub(:request).and_raise(Errno::ETIMEDOUT)
    lambda { @request.transmit(@uri, 'req', nil) }.should raise_error(RestClient::RequestTimeout)
  end

  it "class method execute wraps constructor" do
    req = double("rest request")
    RestClient::Request.should_receive(:new).with(1 => 2).and_return(req)
    req.should_receive(:execute)
    RestClient::Request.execute(1 => 2)
  end

  describe "exception" do
    it "raises Unauthorized when the response is 401" do
      res = double('response', :code => '401', :[] => ['content-encoding' => ''], :body => '' )
      lambda { @request.process_result(res) }.should raise_error(RestClient::Unauthorized)
    end

    it "raises ResourceNotFound when the response is 404" do
      res = double('response', :code => '404', :[] => ['content-encoding' => ''], :body => '' )
      lambda { @request.process_result(res) }.should raise_error(RestClient::ResourceNotFound)
    end

    it "raises RequestFailed otherwise" do
      res = double('response', :code => '500', :[] => ['content-encoding' => ''], :body => '' )
      lambda { @request.process_result(res) }.should raise_error(RestClient::InternalServerError)
    end
  end

  describe "block usage" do
    it "returns what asked to" do
      res = double('response', :code => '401', :[] => ['content-encoding' => ''], :body => '' )
      @request.process_result(res){|response, request| "foo"}.should eq "foo"
    end
  end

  describe "proxy" do
    it "creates a proxy class if a proxy url is given" do
      RestClient.stub(:proxy).and_return("http://example.com/")
      @request.net_http_class.proxy_class?.should be_true
    end

    it "creates a non-proxy class if a proxy url is not given" do
      @request.net_http_class.proxy_class?.should be_false
    end
  end


  describe "logging" do
    it "logs a get request" do
      log = RestClient.log = []
      RestClient::Request.new(:method => :get, :url => 'http://url').log_request
      log[0].should eq %Q{RestClient.get "http://url", "Accept"=>"*/*; q=0.5, application/xml", "Accept-Encoding"=>"gzip, deflate"\n}
    end

    it "logs a post request with a small payload" do
      log = RestClient.log = []
      RestClient::Request.new(:method => :post, :url => 'http://url', :payload => 'foo').log_request
      log[0].should eq %Q{RestClient.post "http://url", "foo", "Accept"=>"*/*; q=0.5, application/xml", "Accept-Encoding"=>"gzip, deflate", "Content-Length"=>"3"\n}
    end

    it "logs a post request with a large payload" do
      log = RestClient.log = []
      RestClient::Request.new(:method => :post, :url => 'http://url', :payload => ('x' * 1000)).log_request
      log[0].should eq %Q{RestClient.post "http://url", 1000 byte(s) length, "Accept"=>"*/*; q=0.5, application/xml", "Accept-Encoding"=>"gzip, deflate", "Content-Length"=>"1000"\n}
    end

    it "logs input headers as a hash" do
      log = RestClient.log = []
      RestClient::Request.new(:method => :get, :url => 'http://url', :headers => { :accept => 'text/plain' }).log_request
      log[0].should eq %Q{RestClient.get "http://url", "Accept"=>"text/plain", "Accept-Encoding"=>"gzip, deflate"\n}
    end

    it "logs a response including the status code, content type, and result body size in bytes" do
      log = RestClient.log = []
      res = double('result', :code => '200', :class => Net::HTTPOK, :body => 'abcd')
      res.stub(:[]).with('Content-type').and_return('text/html')
      @request.log_response res
      log[0].should eq "# => 200 OK | text/html 4 bytes\n"
    end

    it "logs a response with a nil Content-type" do
      log = RestClient.log = []
      res = double('result', :code => '200', :class => Net::HTTPOK, :body => 'abcd')
      res.stub(:[]).with('Content-type').and_return(nil)
      @request.log_response res
      log[0].should eq "# => 200 OK |  4 bytes\n"
    end

    it "logs a response with a nil body" do
      log = RestClient.log = []
      res = double('result', :code => '200', :class => Net::HTTPOK, :body => nil)
      res.stub(:[]).with('Content-type').and_return('text/html; charset=utf-8')
      @request.log_response res
      log[0].should eq "# => 200 OK | text/html 0 bytes\n"
    end

    it 'does not log request password' do
      log = RestClient.log = []
      RestClient::Request.new(:method => :get, :url => 'http://user:password@url', :headers => {:user_agent => 'rest-client', :accept => '*/*'}).log_request
      log[0].should eq %Q{RestClient.get "http://user:REDACTED@url", "Accept"=>"*/*", "Accept-Encoding"=>"gzip, deflate", "User-Agent"=>"rest-client"\n}
    end

    it 'logs invalid URIs, even though they will fail elsewhere' do
      log = RestClient.log = []
      RestClient::Request.new(:method => :get, :url => 'http://a@b:c', :headers => {:user_agent => 'rest-client', :accept => '*/*'}).log_request
      log[0].should eq %Q{RestClient.get "[invalid uri]", "Accept"=>"*/*", "Accept-Encoding"=>"gzip, deflate", "User-Agent"=>"rest-client"\n}
    end
  end

  it "strips the charset from the response content type" do
    log = RestClient.log = []
    res = double('result', :code => '200', :class => Net::HTTPOK, :body => 'abcd')
    res.stub(:[]).with('Content-type').and_return('text/html; charset=utf-8')
    @request.log_response res
    log[0].should eq "# => 200 OK | text/html 4 bytes\n"
  end

  describe "timeout" do
    it "does not set timeouts if not specified" do
      @request = RestClient::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload')
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)

      @net.should_not_receive(:read_timeout=)
      @net.should_not_receive(:open_timeout=)

      @request.transmit(@uri, 'req', nil)
    end

    it "set read_timeout" do
      @request = RestClient::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :timeout => 123)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)

      @net.should_receive(:read_timeout=).with(123)

      @request.transmit(@uri, 'req', nil)
    end

    it "set open_timeout" do
      @request = RestClient::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :open_timeout => 123)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)

      @net.should_receive(:open_timeout=).with(123)

      @request.transmit(@uri, 'req', nil)
    end

    it "disable timeout by setting it to nil" do
      @request = RestClient::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :timeout => nil, :open_timeout => nil)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)

      @net.should_receive(:read_timeout=).with(nil)
      @net.should_receive(:open_timeout=).with(nil)

      @request.transmit(@uri, 'req', nil)
    end

    it "deprecated: disable timeout by setting it to -1" do
      @request = RestClient::Request.new(:method => :put, :url => 'http://some/resource', :payload => 'payload', :timeout => -1, :open_timeout => -1)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)

      @request.should_receive(:warn)
      @net.should_receive(:read_timeout=).with(nil)

      @request.should_receive(:warn)
      @net.should_receive(:open_timeout=).with(nil)

      @request.transmit(@uri, 'req', nil)
    end
  end

  describe "ssl" do
    it "uses SSL when the URI refers to a https address" do
      @uri.stub(:is_a?).with(URI::HTTPS).and_return(true)
      @net.should_receive(:use_ssl=).with(true)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should default to verifying ssl certificates" do
      @request.verify_ssl.should eq OpenSSL::SSL::VERIFY_PEER
    end

    it "should have expected values for VERIFY_PEER and VERIFY_NONE" do
      OpenSSL::SSL::VERIFY_NONE.should eq(0)
      OpenSSL::SSL::VERIFY_PEER.should eq(1)
    end

    it "should set net.verify_mode to OpenSSL::SSL::VERIFY_NONE if verify_ssl is false" do
      @request = RestClient::Request.new(:method => :put, :verify_ssl => false, :url => 'http://some/resource', :payload => 'payload')
      @net.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not set net.verify_mode to OpenSSL::SSL::VERIFY_NONE if verify_ssl is true" do
      @request = RestClient::Request.new(:method => :put, :url => 'https://some/resource', :payload => 'payload', :verify_ssl => true)
      @net.should_not_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should set net.verify_mode to OpenSSL::SSL::VERIFY_PEER if verify_ssl is true" do
      @request = RestClient::Request.new(:method => :put, :url => 'https://some/resource', :payload => 'payload', :verify_ssl => true)
      @net.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should set net.verify_mode to OpenSSL::SSL::VERIFY_PEER if verify_ssl is not given" do
      @request = RestClient::Request.new(:method => :put, :url => 'https://some/resource', :payload => 'payload')
      @net.should_receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should set net.verify_mode to the passed value if verify_ssl is an OpenSSL constant" do
      mode = OpenSSL::SSL::VERIFY_PEER | OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
      @request = RestClient::Request.new( :method => :put,
                                          :url => 'https://some/resource',
                                          :payload => 'payload',
                                          :verify_ssl => mode )
      @net.should_receive(:verify_mode=).with(mode)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should default to not having an ssl_client_cert" do
      @request.ssl_client_cert.should be(nil)
    end

    it "should set the ssl_version if provided" do
      @request = RestClient::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :ssl_version => "TLSv1"
      )
      @net.should_receive(:ssl_version=).with("TLSv1")
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not set the ssl_version if not provided" do
      @request = RestClient::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload'
      )
      @net.should_not_receive(:ssl_version=).with("TLSv1")
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should set the ssl_ciphers if provided" do
      ciphers = 'AESGCM:HIGH:!aNULL:!eNULL:RC4+RSA'
      @request = RestClient::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :ssl_ciphers => ciphers
      )
      @net.should_receive(:ciphers=).with(ciphers)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not set the ssl_ciphers if set to nil" do
      @request = RestClient::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
        :ssl_ciphers => nil,
      )
      @net.should_not_receive(:ciphers=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should override ssl_ciphers with better defaults with weak default ciphers" do
      stub_const(
        '::OpenSSL::SSL::SSLContext::DEFAULT_PARAMS',
        {
          :ssl_version=>"SSLv23",
          :verify_mode=>1,
          :ciphers=>"ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW",
          :options=>-2147480577,
        }
      )

      @request = RestClient::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
      )

      @net.should_receive(:ciphers=).with(RestClient::Request::DefaultCiphers)

      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not override ssl_ciphers with better defaults with different default ciphers" do
      stub_const(
        '::OpenSSL::SSL::SSLContext::DEFAULT_PARAMS',
        {
          :ssl_version=>"SSLv23",
          :verify_mode=>1,
          :ciphers=>"HIGH:!aNULL:!eNULL:!EXPORT:!LOW:!MEDIUM:!SSLv2",
          :options=>-2147480577,
        }
      )

      @request = RestClient::Request.new(
        :method => :put,
        :url => 'https://some/resource',
        :payload => 'payload',
      )

      @net.should_not_receive(:ciphers=)

      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should set the ssl_client_cert if provided" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_client_cert => "whatsupdoc!"
      )
      @net.should_receive(:cert=).with("whatsupdoc!")
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not set the ssl_client_cert if it is not provided" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      @net.should_not_receive(:cert=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should default to not having an ssl_client_key" do
      @request.ssl_client_key.should be(nil)
    end

    it "should set the ssl_client_key if provided" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_client_key => "whatsupdoc!"
      )
      @net.should_receive(:key=).with("whatsupdoc!")
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not set the ssl_client_key if it is not provided" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      @net.should_not_receive(:key=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should default to not having an ssl_ca_file" do
      @request.ssl_ca_file.should be(nil)
    end

    it "should set the ssl_ca_file if provided" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_ca_file => "Certificate Authority File"
      )
      @net.should_receive(:ca_file=).with("Certificate Authority File")
      @net.should_not_receive(:cert_store=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not set the ssl_ca_file if it is not provided" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      @net.should_not_receive(:ca_file=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should default to not having an ssl_ca_path" do
      @request.ssl_ca_path.should be(nil)
    end

    it "should set the ssl_ca_path if provided" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_ca_path => "Certificate Authority Path"
      )
      @net.should_receive(:ca_path=).with("Certificate Authority Path")
      @net.should_not_receive(:cert_store=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not set the ssl_ca_path if it is not provided" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      @net.should_not_receive(:ca_path=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should set the ssl_cert_store if provided" do
      store = OpenSSL::X509::Store.new
      store.set_default_paths

      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_cert_store => store
      )
      @net.should_receive(:cert_store=).with(store)
      @net.should_not_receive(:ca_path=)
      @net.should_not_receive(:ca_file=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should by default set the ssl_cert_store if no CA info is provided" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload'
      )
      @net.should_receive(:cert_store=)
      @net.should_not_receive(:ca_path=)
      @net.should_not_receive(:ca_file=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not set the ssl_cert_store if it is set falsy" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_cert_store => nil,
      )
      @net.should_not_receive(:cert_store=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should not set the ssl_verify_callback by default" do
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
      )
      @net.should_not_receive(:verify_callback=)
      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    it "should set the ssl_verify_callback if passed" do
      callback = lambda {}
      @request = RestClient::Request.new(
              :method => :put,
              :url => 'https://some/resource',
              :payload => 'payload',
              :ssl_verify_callback => callback,
      )
      @net.should_receive(:verify_callback=).with(callback)

      # we'll read cert_store on jruby
      # https://github.com/jruby/jruby/issues/597
      if RestClient::Platform.jruby?
        allow(@net).to receive(:cert_store)
      end

      @http.stub(:request)
      @request.stub(:process_result)
      @request.stub(:response_log)
      @request.transmit(@uri, 'req', 'payload')
    end

    # </ssl>
  end

  it "should still return a response object for 204 No Content responses" do
    @request = RestClient::Request.new(
            :method => :put,
            :url => 'https://some/resource',
            :payload => 'payload'
    )
    net_http_res = Net::HTTPNoContent.new("", "204", "No Content")
    net_http_res.stub(:read_body).and_return(nil)
    @http.should_receive(:request).and_return(@request.fetch_body(net_http_res))
    response = @request.transmit(@uri, 'req', 'payload')
    response.should_not be_nil
    response.code.should eq 204
  end

  describe "raw response" do
    it "should read the response into a binary-mode tempfile" do
      @request = RestClient::Request.new(:method => "get", :url => "example.com", :raw_response => true)

      tempfile = double("tempfile")
      tempfile.should_receive(:binmode)
      tempfile.stub(:open)
      tempfile.stub(:close)
      Tempfile.should_receive(:new).with("rest-client").and_return(tempfile)

      net_http_res = Net::HTTPOK.new(nil, "200", "body")
      net_http_res.stub(:read_body).and_return("body")
      @request.fetch_body(net_http_res)
    end
  end
end
