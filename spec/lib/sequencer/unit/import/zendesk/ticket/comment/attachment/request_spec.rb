# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Zendesk::Ticket::Comment::Attachment::Request, sequencer: :unit do

  context 'when fetching large attachements from Zendesk' do

    let(:mock_parameters) do
      {
        resource: double(
          content_url: ''
        )
      }
    end

    let(:response) { double() }

    it 'open timeout should be 20s and read timeout should be 240s' do
      allow(response).to receive(:success?).and_return(true)
      allow(UserAgent).to receive(:get).with(any_args, { open_timeout: 20, read_timeout: 240 }).and_return(response)
      process(mock_parameters)
      expect(UserAgent).to have_received(:get)
    end
  end
end
