require 'spec_helper'

describe RestClient::Response do
  before do
    @net_http_res = double('net http response', :to_hash => {"Status" => ["200 OK"]}, :code => 200)
    @example_url = 'http://example.com'
    @request = double('http request', :user => nil, :password => nil, :url => @example_url)
    @response = RestClient::Response.create('abc', @net_http_res, {}, @request)
  end

  it "behaves like string" do
    @response.to_s.should eq 'abc'
    @response.to_str.should eq 'abc'
    @response.to_i.should eq 200
  end

  it "accepts nil strings and sets it to empty for the case of HEAD" do
    RestClient::Response.create(nil, @net_http_res, {}, @request).to_s.should eq ""
  end

  it "test headers and raw headers" do
    @response.raw_headers["Status"][0].should eq "200 OK"
    @response.headers[:status].should eq "200 OK"
  end

  describe "cookie processing" do
    it "should correctly deal with one Set-Cookie header with one cookie inside" do
      header_val = "main_page=main_page_no_rewrite; path=/; expires=Sat, 10-Jan-2037 15:03:14 GMT".freeze

      net_http_res = double('net http response', :to_hash => {"etag" => ["\"e1ac1a2df945942ef4cac8116366baad\""], "set-cookie" => [header_val]})
      response = RestClient::Response.create('abc', net_http_res, {}, @request)
      response.headers[:set_cookie].should eq [header_val]
      response.cookies.should eq({ "main_page" => "main_page_no_rewrite" })
    end

    it "should correctly deal with multiple cookies [multiple Set-Cookie headers]" do
      net_http_res = double('net http response', :to_hash => {"etag" => ["\"e1ac1a2df945942ef4cac8116366baad\""], "set-cookie" => ["main_page=main_page_no_rewrite; path=/; expires=Sat, 10-Jan-2037 15:03:14 GMT", "remember_me=; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT", "user=somebody; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT"]})
      response = RestClient::Response.create('abc', net_http_res, {}, @request)
      response.headers[:set_cookie].should eq ["main_page=main_page_no_rewrite; path=/; expires=Sat, 10-Jan-2037 15:03:14 GMT", "remember_me=; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT", "user=somebody; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT"]
      response.cookies.should eq({
        "main_page" => "main_page_no_rewrite",
        "remember_me" => "",
        "user" => "somebody"
      })
    end

    it "should correctly deal with multiple cookies [one Set-Cookie header with multiple cookies]" do
      net_http_res = double('net http response', :to_hash => {"etag" => ["\"e1ac1a2df945942ef4cac8116366baad\""], "set-cookie" => ["main_page=main_page_no_rewrite; path=/; expires=Sat, 10-Jan-2037 15:03:14 GMT, remember_me=; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT, user=somebody; path=/; expires=Sat, 10-Jan-2037 00:00:00 GMT"]})
      response = RestClient::Response.create('abc', net_http_res, {}, @request)
      response.cookies.should eq({
        "main_page" => "main_page_no_rewrite",
        "remember_me" => "",
        "user" => "somebody"
      })
    end
  end

  describe "exceptions processing" do
    it "should return itself for normal codes" do
      (200..206).each do |code|
        net_http_res = double('net http response', :code => '200')
        response = RestClient::Response.create('abc', net_http_res, {}, @request)
        response.return! @request
      end
    end

    it "should throw an exception for other codes" do
      RestClient::Exceptions::EXCEPTIONS_MAP.each_key do |code|
        unless (200..207).include? code
          net_http_res = double('net http response', :code => code.to_i)
          response = RestClient::Response.create('abc', net_http_res, {}, @request)
          lambda { response.return!}.should raise_error
        end
      end
    end

  end

  describe "redirection" do

    it "follows a redirection when the request is a get" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://new/resource'})
      stub_request(:get, 'http://new/resource').to_return(:body => 'Foo')
      RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body.should eq 'Foo'
    end

    it "follows a redirection and keep the parameters" do
      stub_request(:get, 'http://foo:bar@some/resource').with(:headers => {'Accept' => 'application/json'}).to_return(:body => '', :status => 301, :headers => {'Location' => 'http://new/resource'})
      stub_request(:get, 'http://foo:bar@new/resource').with(:headers => {'Accept' => 'application/json'}).to_return(:body => 'Foo')
      RestClient::Request.execute(:url => 'http://some/resource', :method => :get, :user => 'foo', :password => 'bar', :headers => {:accept => :json}).body.should eq 'Foo'
    end

    it "follows a redirection and keep the cookies" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Set-Cookie' => 'Foo=Bar', 'Location' => 'http://some/new_resource', })
      stub_request(:get, 'http://some/new_resource').with(:headers => {'Cookie' => 'Foo=Bar'}).to_return(:body => 'Qux')
      RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body.should eq 'Qux'
    end

    it 'does not keep cookies across domains' do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Set-Cookie' => 'Foo=Bar', 'Location' => 'http://new/resource', })
      stub_request(:get, 'http://new/resource').with(:headers => {'Cookie' => ''}).to_return(:body => 'Qux')
      RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body.should eq 'Qux'
    end

    it "doesn't follow a 301 when the request is a post" do
      net_http_res = double('net http response', :code => 301)
      response = RestClient::Response.create('abc', net_http_res, {:method => :post}, @request)
      lambda { response.return!(@request)}.should raise_error(RestClient::MovedPermanently)
    end

    it "doesn't follow a 302 when the request is a post" do
      net_http_res = double('net http response', :code => 302)
      response = RestClient::Response.create('abc', net_http_res, {:method => :post}, @request)
      lambda { response.return!(@request)}.should raise_error(RestClient::Found)
    end

    it "doesn't follow a 307 when the request is a post" do
      net_http_res = double('net http response', :code => 307)
      response = RestClient::Response.create('abc', net_http_res, {:method => :post}, @request)
      lambda { response.return!(@request)}.should raise_error(RestClient::TemporaryRedirect)
    end

    it "doesn't follow a redirection when the request is a put" do
      net_http_res = double('net http response', :code => 301)
      response = RestClient::Response.create('abc', net_http_res, {:method => :put}, @request)
      lambda { response.return!(@request)}.should raise_error(RestClient::MovedPermanently)
    end

    it "follows a redirection when the request is a post and result is a 303" do
      stub_request(:put, 'http://some/resource').to_return(:body => '', :status => 303, :headers => {'Location' => 'http://new/resource'})
      stub_request(:get, 'http://new/resource').to_return(:body => 'Foo')
      RestClient::Request.execute(:url => 'http://some/resource', :method => :put).body.should eq 'Foo'
    end

    it "follows a redirection when the request is a head" do
      stub_request(:head, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://new/resource'})
      stub_request(:head, 'http://new/resource').to_return(:body => 'Foo')
      RestClient::Request.execute(:url => 'http://some/resource', :method => :head).body.should eq 'Foo'
    end

    it "handles redirects with relative paths" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'index'})
      stub_request(:get, 'http://some/index').to_return(:body => 'Foo')
      RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body.should eq 'Foo'
    end

    it "handles redirects with relative path and query string" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'index?q=1'})
      stub_request(:get, 'http://some/index?q=1').to_return(:body => 'Foo')
      RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body.should eq 'Foo'
    end

    it "follow a redirection when the request is a get and the response is in the 30x range" do
      stub_request(:get, 'http://some/resource').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://new/resource'})
      stub_request(:get, 'http://new/resource').to_return(:body => 'Foo')
      RestClient::Request.execute(:url => 'http://some/resource', :method => :get).body.should eq 'Foo'
    end

    it "follows no more than 10 redirections before raising error" do
      stub_request(:get, 'http://some/redirect-1').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://some/redirect-2'})
      stub_request(:get, 'http://some/redirect-2').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://some/redirect-2'})
      lambda { RestClient::Request.execute(:url => 'http://some/redirect-1', :method => :get) }.should raise_error(RestClient::MaxRedirectsReached)
      WebMock.should have_requested(:get, 'http://some/redirect-2').times(10)
    end

    it "follows no more than max_redirects redirections, if specified" do
      stub_request(:get, 'http://some/redirect-1').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://some/redirect-2'})
      stub_request(:get, 'http://some/redirect-2').to_return(:body => '', :status => 301, :headers => {'Location' => 'http://some/redirect-2'})
      lambda { RestClient::Request.execute(:url => 'http://some/redirect-1', :method => :get, :max_redirects => 5) }.should raise_error(RestClient::MaxRedirectsReached)
      WebMock.should have_requested(:get, 'http://some/redirect-2').times(5)
    end
  end


end
