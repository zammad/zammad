require_relative '_lib'

describe RestClient::RawResponse do
  before do
    @tf = double("Tempfile", :read => "the answer is 42", :open => true)
    @net_http_res = double('net http response')
    @request = double('http request')
    @response = RestClient::RawResponse.new(@tf, @net_http_res, @request)
  end

  it "behaves like string" do
    expect(@response.to_s).to eq 'the answer is 42'
  end

  it "exposes a Tempfile" do
    expect(@response.file).to eq @tf
  end
end
