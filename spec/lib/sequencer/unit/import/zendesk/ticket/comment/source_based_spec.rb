# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Zendesk::Ticket::Comment::SourceBased, sequencer: :unit do

  before(:all) do

    described_class.class_eval do

      private

      def email
        'test@example.com'
      end
    end
  end

  def parameters_for_channel(channel)
    {
      resource: double(
        via: double(
          channel: channel
        )
      )
    }
  end

  context 'for resource.via.channel attribute' do

    it 'provides from existing method' do
      provided = process(parameters_for_channel('email'))
      expect(provided[:source_based]).to eq('test@example.com')
    end

    it 'provides nil for non existing method' do
      provided = process(parameters_for_channel('system'))
      expect(provided[:source_based]).to be_nil
    end
  end
end
