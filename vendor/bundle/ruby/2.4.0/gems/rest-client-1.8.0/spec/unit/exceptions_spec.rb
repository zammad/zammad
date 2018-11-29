require 'spec_helper'

describe RestClient::Exception do
  it "returns a 'message' equal to the class name if the message is not set, because 'message' should not be nil" do
    e = RestClient::Exception.new
    e.message.should eq "RestClient::Exception"
  end

  it "returns the 'message' that was set" do
    e = RestClient::Exception.new
    message = "An explicitly set message"
    e.message = message
    e.message.should eq message
  end

  it "sets the exception message to ErrorMessage" do
    RestClient::ResourceNotFound.new.message.should eq 'Resource Not Found'
  end

  it "contains exceptions in RestClient" do
    RestClient::Unauthorized.new.should be_a_kind_of(RestClient::Exception)
    RestClient::ServerBrokeConnection.new.should be_a_kind_of(RestClient::Exception)
  end
end

describe RestClient::ServerBrokeConnection do
  it "should have a default message of 'Server broke connection'" do
    e = RestClient::ServerBrokeConnection.new
    e.message.should eq 'Server broke connection'
  end
end

describe RestClient::RequestFailed do
  before do
    @response = double('HTTP Response', :code => '502')
  end

  it "stores the http response on the exception" do
    response = "response"
    begin
      raise RestClient::RequestFailed, response
    rescue RestClient::RequestFailed => e
      e.response.should eq response
    end
  end

  it "http_code convenience method for fetching the code as an integer" do
    RestClient::RequestFailed.new(@response).http_code.should eq 502
  end

  it "http_body convenience method for fetching the body (decoding when necessary)" do
    RestClient::RequestFailed.new(@response).http_code.should eq 502
    RestClient::RequestFailed.new(@response).message.should eq 'HTTP status code 502'
  end

  it "shows the status code in the message" do
    RestClient::RequestFailed.new(@response).to_s.should match(/502/)
  end
end

describe RestClient::ResourceNotFound do
  it "also has the http response attached" do
    response = "response"
    begin
      raise RestClient::ResourceNotFound, response
    rescue RestClient::ResourceNotFound => e
      e.response.should eq response
    end
  end
end

describe "backwards compatibility" do
  it "alias RestClient::Request::Redirect to RestClient::Redirect" do
    RestClient::Request::Redirect.should eq RestClient::Redirect
  end

  it "alias RestClient::Request::Unauthorized to RestClient::Unauthorized" do
    RestClient::Request::Unauthorized.should eq RestClient::Unauthorized
  end

  it "alias RestClient::Request::RequestFailed to RestClient::RequestFailed" do
    RestClient::Request::RequestFailed.should eq RestClient::RequestFailed
  end

  it "make the exception's response act like an Net::HTTPResponse" do
    body = "body"
    stub_request(:get, "www.example.com").to_return(:body => body, :status => 404)
    begin
      RestClient.get "www.example.com"
      raise
    rescue RestClient::ResourceNotFound => e
      e.response.body.should eq body
    end
  end
end
