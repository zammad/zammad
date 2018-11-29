require 'spec_helper'

describe Koala::HTTPService::MultipartRequest do
  it "is a subclass of Faraday::Request::Multipart" do
    expect(Koala::HTTPService::MultipartRequest.superclass).to eq(Faraday::Request::Multipart)
  end

  it "defines mime_type as multipart/form-data" do
    expect(Koala::HTTPService::MultipartRequest.mime_type).to eq('multipart/form-data')
  end

  describe "#process_request?" do
    before :each do
      @env = Faraday::Env.new
      @multipart = Koala::HTTPService::MultipartRequest.new
      allow(@multipart).to receive(:request_type).and_return("")
    end

    # no way to test the call to super, unfortunately
    it "returns true if env[:body] is a hash with at least one hash in its values" do
      @env[:body] = {:a => {:c => 2}}
      expect(@multipart.process_request?(@env)).to be_truthy
    end

    it "returns true if env[:body] is a hash with at least one array in its values" do
      @env[:body] = {:a => [:c, 2]}
      expect(@multipart.process_request?(@env)).to be_truthy
    end

    it "returns true if env[:body] is a hash with mixed objects in its values" do
      @env[:body] = {:a => [:c, 2], :b => {:e => :f}}
      expect(@multipart.process_request?(@env)).to be_truthy
    end

    it "returns false if env[:body] is a string" do
      @env[:body] = "my body"
      expect(@multipart.process_request?(@env)).to be_falsey
    end

    it "returns false if env[:body] is a hash without an array or hash value" do
      @env[:body] = {:a => 3}
      expect(@multipart.process_request?(@env)).to be_falsey
    end
  end

  describe "#process_params" do
    before :each do
      @parent = Faraday::Request::Multipart.new
      @multipart = Koala::HTTPService::MultipartRequest.new
      @block = lambda {|k, v| "#{k}=#{v}"}
    end

    it "is identical to the parent for requests without a prefix" do
      hash = {:a => 2, :c => "3"}
      expect(@multipart.process_params(hash, &@block)).to eq(@parent.process_params(hash, &@block))
    end

    it "replaces encodes [ and ] if the request has a prefix" do
      hash = {:a => 2, :c => "3"}
      prefix = "foo"
      # process_params returns an array
      expect(@multipart.process_params(hash, prefix, &@block).join("&")).to eq(@parent.process_params(hash, prefix, &@block).join("&").gsub(/\[/, "%5B").gsub(/\]/, "%5D"))
    end
  end
end