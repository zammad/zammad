# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Import::OTRS::Requester do

  describe '.list' do
    it 'responds to list' do
      expect(described_class).to respond_to(:list)
    end
  end

  describe '.load' do

    it 'responds to load' do
      expect(described_class).to respond_to(:load)
    end

    context 'caching request results' do

      let(:response) do
        response      = double()
        response_body = double()
        allow(response_body).to receive(:to_s).at_least(:once).and_return('{"Result": {}}')
        allow(response).to receive('success?').at_least(:once).and_return(true)
        allow(response).to receive('body').at_least(:once).and_return(response_body)
        response
      end

      it 'is active if no args are given' do
        allow(UserAgent).to receive(:post).and_return(response)
        described_class.load('Ticket')
        described_class.load('Ticket')
      end

      it 'is not active if args are given' do
        allow(UserAgent).to receive(:post).twice.and_return(response)
        described_class.load('Ticket', offset: 10)
        described_class.load('Ticket', offset: 20)
      end
    end
  end

  describe '.connection_test' do
    it 'responds to connection_test' do
      expect(described_class).to respond_to(:connection_test)
    end
  end

  it 'retries request 3 times on errors' do
    expect(UserAgent).to receive(:post).and_raise(Errno::ECONNRESET).exactly(3).times
    # disable sleep time to speed up tests
    described_class.retry_sleep = 0
    expect { described_class.list }.to raise_error(Errno::ECONNRESET)
  end
end
