require 'spec_helper'

describe RestClient::Resource do
  before do
    @resource = RestClient::Resource.new('http://some/resource', :user => 'jane', :password => 'mypass', :headers => {'X-Something' => '1'})
  end

  context "Resource delegation" do
    it "GET" do
      RestClient::Request.should_receive(:execute).with(:method => :get, :url => 'http://some/resource', :headers => {'X-Something' => '1'}, :user => 'jane', :password => 'mypass')
      @resource.get
    end

    it "HEAD" do
      RestClient::Request.should_receive(:execute).with(:method => :head, :url => 'http://some/resource', :headers => {'X-Something' => '1'}, :user => 'jane', :password => 'mypass')
      @resource.head
    end

    it "POST" do
      RestClient::Request.should_receive(:execute).with(:method => :post, :url => 'http://some/resource', :payload => 'abc', :headers => {:content_type => 'image/jpg', 'X-Something' => '1'}, :user => 'jane', :password => 'mypass')
      @resource.post 'abc', :content_type => 'image/jpg'
    end

    it "PUT" do
      RestClient::Request.should_receive(:execute).with(:method => :put, :url => 'http://some/resource', :payload => 'abc', :headers => {:content_type => 'image/jpg', 'X-Something' => '1'}, :user => 'jane', :password => 'mypass')
      @resource.put 'abc', :content_type => 'image/jpg'
    end

    it "PATCH" do
      RestClient::Request.should_receive(:execute).with(:method => :patch, :url => 'http://some/resource', :payload => 'abc', :headers => {:content_type => 'image/jpg', 'X-Something' => '1'}, :user => 'jane', :password => 'mypass')
      @resource.patch 'abc', :content_type => 'image/jpg'
    end

    it "DELETE" do
      RestClient::Request.should_receive(:execute).with(:method => :delete, :url => 'http://some/resource', :headers => {'X-Something' => '1'}, :user => 'jane', :password => 'mypass')
      @resource.delete
    end

    it "overrides resource headers" do
      RestClient::Request.should_receive(:execute).with(:method => :get, :url => 'http://some/resource', :headers => {'X-Something' => '2'}, :user => 'jane', :password => 'mypass')
      @resource.get 'X-Something' => '2'
    end
  end

  it "can instantiate with no user/password" do
    @resource = RestClient::Resource.new('http://some/resource')
  end

  it "is backwards compatible with previous constructor" do
    @resource = RestClient::Resource.new('http://some/resource', 'user', 'pass')
    @resource.user.should eq 'user'
    @resource.password.should eq 'pass'
  end

  it "concatenates urls, inserting a slash when it needs one" do
    @resource.concat_urls('http://example.com', 'resource').should eq 'http://example.com/resource'
  end

  it "concatenates urls, using no slash if the first url ends with a slash" do
    @resource.concat_urls('http://example.com/', 'resource').should eq 'http://example.com/resource'
  end

  it "concatenates urls, using no slash if the second url starts with a slash" do
    @resource.concat_urls('http://example.com', '/resource').should eq 'http://example.com/resource'
  end

  it "concatenates even non-string urls, :posts + 1 => 'posts/1'" do
    @resource.concat_urls(:posts, 1).should eq 'posts/1'
  end

  it "offers subresources via []" do
    parent = RestClient::Resource.new('http://example.com')
    parent['posts'].url.should eq 'http://example.com/posts'
  end

  it "transports options to subresources" do
    parent = RestClient::Resource.new('http://example.com', :user => 'user', :password => 'password')
    parent['posts'].user.should eq 'user'
    parent['posts'].password.should eq 'password'
  end

  it "passes a given block to subresources" do
    block = proc {|r| r}
    parent = RestClient::Resource.new('http://example.com', &block)
    parent['posts'].block.should eq block
  end

  it "the block should be overrideable" do
    block1 = proc {|r| r}
    block2 = proc {|r| }
    parent = RestClient::Resource.new('http://example.com', &block1)
    # parent['posts', &block2].block.should eq block2 # ruby 1.9 syntax
    parent.send(:[], 'posts', &block2).block.should eq block2
    parent.send(:[], 'posts', &block2).block.should_not eq block1
  end

  it "the block should be overrideable in ruby 1.9 syntax" do
    block1 = proc {|r| r}
    block2 = ->(r) {}

    parent = RestClient::Resource.new('http://example.com', &block1)
    parent['posts', &block2].block.should eq block2
    parent['posts', &block2].block.should_not eq block1
  end

  it "prints its url with to_s" do
    RestClient::Resource.new('x').to_s.should eq 'x'
  end

  describe 'block' do
    it 'can use block when creating the resource' do
      stub_request(:get, 'www.example.com').to_return(:body => '', :status => 404)
      resource = RestClient::Resource.new('www.example.com') { |response, request| 'foo' }
      resource.get.should eq 'foo'
    end

    it 'can use block when executing the resource' do
      stub_request(:get, 'www.example.com').to_return(:body => '', :status => 404)
      resource = RestClient::Resource.new('www.example.com')
      resource.get { |response, request| 'foo' }.should eq 'foo'
    end

    it 'execution block override resource block' do
      stub_request(:get, 'www.example.com').to_return(:body => '', :status => 404)
      resource = RestClient::Resource.new('www.example.com') { |response, request| 'foo' }
      resource.get { |response, request| 'bar' }.should eq 'bar'
    end

  end
end
