require 'spec_helper'

describe RestClient do
  describe "API" do
    it "GET" do
      RestClient::Request.should_receive(:execute).with(:method => :get, :url => 'http://some/resource', :headers => {})
      RestClient.get('http://some/resource')
    end

    it "POST" do
      RestClient::Request.should_receive(:execute).with(:method => :post, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      RestClient.post('http://some/resource', 'payload')
    end

    it "PUT" do
      RestClient::Request.should_receive(:execute).with(:method => :put, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      RestClient.put('http://some/resource', 'payload')
    end

    it "PATCH" do
      RestClient::Request.should_receive(:execute).with(:method => :patch, :url => 'http://some/resource', :payload => 'payload', :headers => {})
      RestClient.patch('http://some/resource', 'payload')
    end

    it "DELETE" do
      RestClient::Request.should_receive(:execute).with(:method => :delete, :url => 'http://some/resource', :headers => {})
      RestClient.delete('http://some/resource')
    end

    it "HEAD" do
      RestClient::Request.should_receive(:execute).with(:method => :head, :url => 'http://some/resource', :headers => {})
      RestClient.head('http://some/resource')
    end

    it "OPTIONS" do
      RestClient::Request.should_receive(:execute).with(:method => :options, :url => 'http://some/resource', :headers => {})
      RestClient.options('http://some/resource')
    end
  end

  describe "logging" do
    after do
      RestClient.log = nil
    end

    it "uses << if the log is not a string" do
      log = RestClient.log = []
      log.should_receive(:<<).with('xyz')
      RestClient.log << 'xyz'
    end

    it "displays the log to stdout" do
      RestClient.log = 'stdout'
      STDOUT.should_receive(:puts).with('xyz')
      RestClient.log << 'xyz'
    end

    it "displays the log to stderr" do
      RestClient.log = 'stderr'
      STDERR.should_receive(:puts).with('xyz')
      RestClient.log << 'xyz'
    end

    it "append the log to the requested filename" do
      RestClient.log = '/tmp/restclient.log'
      f = double('file handle')
      File.should_receive(:open).with('/tmp/restclient.log', 'a').and_yield(f)
      f.should_receive(:puts).with('xyz')
      RestClient.log << 'xyz'
    end
  end

  describe 'version' do
    it 'has a version ~> 1.8.0.alpha' do
      ver = Gem::Version.new(RestClient.version)
      Gem::Requirement.new('~> 1.8.0.alpha').should be_satisfied_by(ver)
    end
  end
end
