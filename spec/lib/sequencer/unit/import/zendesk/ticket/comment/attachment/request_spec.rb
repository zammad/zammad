require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Zendesk::Ticket::Comment::Attachment::Request, sequencer: :unit do

  context 'when fetching large attachements from Zendesk' do

    before(:all) do

      described_class.class_eval do

        private

        def failed?
          false
        end
      end
    end

    def mock_parameters
      {
        resource: double(
          content_url: ''
        )
      }
    end

    it 'open timeout should be 20s and read timeout should be 240s' do
      expect(UserAgent).to receive(:get).with(any_args, { open_timeout: 20, read_timeout: 240 })
      process(mock_parameters)
    end
  end
end
