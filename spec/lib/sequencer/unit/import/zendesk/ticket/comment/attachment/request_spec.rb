# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Zendesk::Ticket::Comment::Attachment::Request, sequencer: :unit do

  context 'when fetching large attachements from Zendesk' do

    let(:mock_parameters) do
      {
        resource: double(
          content_url: ''
        ),
        instance: double(
          id:        2,
          ticket_id: 1,
        ),
      }
    end

    let(:response)      { double }
    let(:read_timeout)  { ENV.fetch('ZAMMAD_HTTP_IMPORT_ATTACHMENT_READ_TIMEOUT', 240).to_i }
    let(:total_timeout) { ENV.fetch('ZAMMAD_HTTP_IMPORT_ATTACHMENT_TOTAL_TIMEOUT', 240).to_i }

    before do
      allow_any_instance_of(described_class).to receive(:sleep)
    end

    it 'read and total timeout should be 240s' do
      allow(response).to receive(:success?).and_return(true)
      allow(UserAgent).to receive(:get).with(any_args, { read_timeout: read_timeout, total_timeout: total_timeout, verify_ssl: true }).and_return(response)
      process(mock_parameters)
      expect(UserAgent).to have_received(:get)
    end

    it 'skip action after defined retries' do
      allow(response).to receive_messages(success?: false, error: '#<Net::HTTPServiceUnavailable 503 Service Unavailable readbody=true>')
      allow(UserAgent).to receive(:get).with(any_args, { read_timeout: read_timeout, total_timeout: total_timeout, verify_ssl: true }).and_return(response)

      result = process(mock_parameters)
      expect(result[:action]).to eq(:skipped)
    end
  end
end
