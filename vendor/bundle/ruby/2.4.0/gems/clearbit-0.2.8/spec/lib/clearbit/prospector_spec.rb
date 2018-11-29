require 'spec_helper'

describe Clearbit::Prospector do
  before do |example|
    Clearbit.key = 'clearbit_key'
  end

  context 'Prospector API' do
    it 'should call out to the Prospector API' do
      body  = []

      stub_request(:get, "https://prospector.clearbit.com/v1/people/search?domain=stripe.com").
        with(:headers => {'Authorization'=>'Bearer clearbit_key'}).
        to_return(:status => 200, :body => body.to_json, headers: {'Content-Type' => 'application/json'})

      Clearbit::Prospector.search(domain: 'stripe.com')
    end
  end
end
