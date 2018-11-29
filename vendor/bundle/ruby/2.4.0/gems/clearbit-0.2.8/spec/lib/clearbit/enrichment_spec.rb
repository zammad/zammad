require 'spec_helper'

describe Clearbit::Enrichment do
  before do |example|
    Clearbit.key = 'clearbit_key'
  end

  context 'combined API' do
    it 'should call out to the combined API' do
      body = {
        person: nil,
        company: nil
      }

      stub_request(:get, 'https://person.clearbit.com/v2/combined/find?email=test@example.com').
        with(:headers => {'Authorization'=>'Bearer clearbit_key'}).
        to_return(:status => 200, :body => body.to_json, headers: {'Content-Type' => 'application/json'})

      Clearbit::Enrichment.find(email: 'test@example.com')
    end

    it 'uses streaming option' do
      body = {
        person: nil,
        company: nil
      }

      stub_request(:get, 'https://person-stream.clearbit.com/v2/combined/find?email=test@example.com').
        with(:headers => {'Authorization'=>'Bearer clearbit_key'}).
        to_return(:status => 200, :body => body.to_json, headers: {'Content-Type' => 'application/json'})

      Clearbit::Enrichment.find(email: 'test@example.com', stream: true)
    end

    it 'accepts request option' do
      body = {
        person: nil,
        company: nil
      }

      stub_request(:get, 'https://person.clearbit.com/v2/combined/find?email=test@example.com').
        with(:headers => {'Authorization'=>'Bearer clearbit_key', 'X-Rated' => 'true'}).
        to_return(:status => 200, :body => body.to_json, headers: {'Content-Type' => 'application/json'})

      Clearbit::Enrichment.find(email: 'test@example.com', request: {headers: {'X-Rated' => 'true'}})
    end

    it 'returns pending? if 202 response' do
      body = {
        person: nil,
        company: nil
      }

      stub_request(:get, 'https://person.clearbit.com/v2/combined/find?email=test@example.com').
        with(:headers => {'Authorization'=>'Bearer clearbit_key'}).
        to_return(:status => 202, :body => body.to_json, headers: {'Content-Type' => 'application/json'})

      result = Clearbit::Enrichment.find(email: 'test@example.com')

      expect(result.pending?).to be true
    end

    it 'should use the Company API if domain is provided' do
      body = {}

      stub_request(:get, 'https://company.clearbit.com/v2/companies/find?domain=example.com').
        with(:headers => {'Authorization'=>'Bearer clearbit_key'}).
        to_return(:status => 200, :body => body.to_json, headers: {'Content-Type' => 'application/json'})

      Clearbit::Enrichment.find(domain: 'example.com')
    end
  end

  context 'person API' do
    it 'should call out to the person API' do
      body = {}

      stub_request(:get, 'https://person.clearbit.com/v2/people/find?email=test@example.com').
        with(:headers => {'Authorization'=>'Bearer clearbit_key'}).
        to_return(:status => 200, :body => body.to_json, headers: {'Content-Type' => 'application/json'})

      Clearbit::Enrichment::Person.find(email: 'test@example.com')
    end
  end

  context 'company API' do
    it 'should call out to the company API' do
      body = {}

      stub_request(:get, 'https://company.clearbit.com/v2/companies/find?domain=example.com').
        with(:headers => {'Authorization'=>'Bearer clearbit_key'}).
        to_return(:status => 200, :body => body.to_json, headers: {'Content-Type' => 'application/json'})

      Clearbit::Enrichment::Company.find(domain: 'example.com')
    end
  end
end
