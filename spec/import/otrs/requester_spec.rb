require 'rails_helper'

RSpec.describe Import::OTRS::Requester do
  it 'responds to load' do
    expect(described_class).to respond_to('load')
  end

  it 'responds to list' do
    expect(described_class).to respond_to('list')
  end

  it 'responds to connection_test' do
    expect(described_class).to respond_to('connection_test')
  end

  context 'caching request results' do

    let(:response) {
      response      = double()
      response_body = double()
      expect(response_body).to receive(:to_s).at_least(:once).and_return('{"Result": {}}')
      expect(response).to receive('success?').at_least(:once).and_return(true)
      expect(response).to receive('body').at_least(:once).and_return(response_body)
      response
    }

    it 'is active if no args are given' do
      expect(UserAgent).to receive(:post).and_return(response)
      described_class.load('Ticket')
      described_class.load('Ticket')
    end

    it 'is not active if args are given' do
      expect(UserAgent).to receive(:post).twice.and_return(response)
      described_class.load('Ticket', offset: 10)
      described_class.load('Ticket', offset: 20)
    end
  end
end
