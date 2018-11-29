require 'spec_helper'

describe RestClient::RawResponse do
  before do
    @tf = double("Tempfile", :read => "the answer is 42", :open => true)
    @net_http_res = double('net http response')
    @request = double('http request')
    @response = RestClient::RawResponse.new(@tf, @net_http_res, {}, @request)
  end

  it "behaves like string" do
    @response.to_s.should eq 'the answer is 42'
  end

  it "exposes a Tempfile" do
    @response.file.should eq @tf
  end
end
