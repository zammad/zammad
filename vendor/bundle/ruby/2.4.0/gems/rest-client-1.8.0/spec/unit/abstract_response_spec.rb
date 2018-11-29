require 'spec_helper'

describe RestClient::AbstractResponse do

  class MyAbstractResponse

    include RestClient::AbstractResponse

    attr_accessor :size

    def initialize net_http_res, args, request
      @net_http_res = net_http_res
      @args = args
      @request = request
    end

  end

  before do
    @net_http_res = double('net http response')
    @request = double('restclient request', :url => 'http://example.com')
    @response = MyAbstractResponse.new(@net_http_res, {}, @request)
  end

  it "fetches the numeric response code" do
    @net_http_res.should_receive(:code).and_return('200')
    @response.code.should eq 200
  end

  it "has a nice description" do
    @net_http_res.should_receive(:to_hash).and_return({'Content-Type' => ['application/pdf']})
    @net_http_res.should_receive(:code).and_return('200')
    @response.description.should eq "200 OK | application/pdf  bytes\n"
  end

  it "beautifies the headers by turning the keys to symbols" do
    h = RestClient::AbstractResponse.beautify_headers('content-type' => [ 'x' ])
    h.keys.first.should eq :content_type
  end

  it "beautifies the headers by turning the values to strings instead of one-element arrays" do
    h = RestClient::AbstractResponse.beautify_headers('x' => [ 'text/html' ] )
    h.values.first.should eq 'text/html'
  end

  it "fetches the headers" do
    @net_http_res.should_receive(:to_hash).and_return('content-type' => [ 'text/html' ])
    @response.headers.should eq({ :content_type => 'text/html' })
  end

  it "extracts cookies from response headers" do
    @net_http_res.should_receive(:to_hash).and_return('set-cookie' => ['session_id=1; path=/'])
    @response.cookies.should eq({ 'session_id' => '1' })
  end

  it "extract strange cookies" do
    @net_http_res.should_receive(:to_hash).and_return('set-cookie' => ['session_id=ZJ/HQVH6YE+rVkTpn0zvTQ==; path=/'])
    @response.headers.should eq({:set_cookie => ['session_id=ZJ/HQVH6YE+rVkTpn0zvTQ==; path=/']})
    @response.cookies.should eq({ 'session_id' => 'ZJ/HQVH6YE+rVkTpn0zvTQ==' })
  end

  it "doesn't escape cookies" do
    @net_http_res.should_receive(:to_hash).and_return('set-cookie' => ['session_id=BAh7BzoNYXBwX25hbWUiEGFwcGxpY2F0aW9uOgpsb2dpbiIKYWRtaW4%3D%0A--08114ba654f17c04d20dcc5228ec672508f738ca; path=/'])
    @response.cookies.should eq({ 'session_id' => 'BAh7BzoNYXBwX25hbWUiEGFwcGxpY2F0aW9uOgpsb2dpbiIKYWRtaW4%3D%0A--08114ba654f17c04d20dcc5228ec672508f738ca' })
  end

  it "can access the net http result directly" do
    @response.net_http_res.should eq @net_http_res
  end

  describe "#return!" do
    it "should return the response itself on 200-codes" do
      @net_http_res.should_receive(:code).and_return('200')
      @response.return!.should be_equal(@response)
    end

    it "should raise RequestFailed on unknown codes" do
      @net_http_res.should_receive(:code).and_return('1000')
      lambda { @response.return! }.should raise_error RestClient::RequestFailed
    end

    it "should raise an error on a redirection after non-GET/HEAD requests" do
      @net_http_res.should_receive(:code).and_return('301')
      @response.args.merge(:method => :put)
      lambda { @response.return! }.should raise_error RestClient::RequestFailed
    end
  end
end
