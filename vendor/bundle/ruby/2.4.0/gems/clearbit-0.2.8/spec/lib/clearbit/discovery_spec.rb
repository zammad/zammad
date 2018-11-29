require 'spec_helper'

describe Clearbit::Discovery do
  before do |example|
    Clearbit.key = 'clearbit_key'
  end

  it 'returns results from the Discovery API' do
    body  = []
    query = {query: {name: 'stripe'}}

    stub_request(:post, "https://discovery.clearbit.com/v1/companies/search").
      with(:headers => {'Authorization'=>'Bearer clearbit_key'}, body: query.to_json).
      to_return(:status => 200, :body => body.to_json, headers: {'Content-Type' => 'application/json'})

    Clearbit::Discovery.search(query: {name: 'stripe'})
  end
end
