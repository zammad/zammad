# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::Requester do
  let(:response_body) { '{"Success": 1, "Result": {"Ticket": 42}}' }
  let(:response)      { instance_double(UserAgent::Result, success?: true, body: response_body) }

  around do |example|
    described_class.instance_variable_set(:@cache, nil)
    example.run
    described_class.instance_variable_set(:@cache, nil)
  end

  before do
    allow(UserAgent).to receive(:post).and_return(response)
  end

  describe '.list' do
    it 'returns the result of the list request', :aggregate_failures do
      expect(described_class.list).to eq({ 'Ticket' => 42 })
      expect(UserAgent).to have_received(:post).with(anything, hash_including(Subaction: 'List', Action: 'ZammadMigrator'), anything)
    end
  end

  describe '.load' do
    context 'caching request results' do
      it 'is active if no args are given' do
        described_class.load('Ticket')
        described_class.load('Ticket')

        expect(UserAgent).to have_received(:post).once
      end

      it 'is not active if args are given' do
        described_class.load('Ticket', offset: 10)
        described_class.load('Ticket', offset: 20)

        expect(UserAgent).to have_received(:post).twice
      end
    end
  end

  describe '.connection_test' do
    it 'returns true for a successful response' do
      expect(described_class.connection_test).to be true
    end

    context 'when the response is not successful' do
      let(:response_body) { '{"Success": false}' }

      it 'raises an error' do
        expect { described_class.connection_test }.to raise_error(RuntimeError, 'API key not valid!')
      end
    end
  end

  it 'retries request 3 times on errors', :aggregate_failures do
    allow(UserAgent).to receive(:post).and_raise(Errno::ECONNRESET)
    allow(described_class).to receive(:sleep)

    expect { described_class.list }.to raise_error(Errno::ECONNRESET)
    expect(UserAgent).to have_received(:post).exactly(3).times
  end
end
