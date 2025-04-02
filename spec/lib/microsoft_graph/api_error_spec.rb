# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe MicrosoftGraph::ApiError do
  subject(:instance) { described_class.new(error_hash) }

  let(:error_hash) do
    {
      code:       'badRequest',
      message:    'Uploaded fragment overlaps with existing data.',
      innerError: {
        code:         'invalidRange',
        'request-id': 'request-id',
        date:         'date-time'
      }
    }
  end

  describe '#message' do
    context 'with full error hash' do
      it 'generates correct message' do
        expect(instance.message).to eq("Uploaded fragment overlaps with existing data. (badRequest)\nMicrosoft Graph API Request ID: request-id")
      end
    end

    context 'with incomplete error hash' do
      let(:error_hash) do
        {
          message: 'Uploaded fragment overlaps with existing data.',
        }
      end

      it 'generates correct message' do
        expect(instance.message).to eq('Uploaded fragment overlaps with existing data. (no error code present)')
      end
    end

    context 'without error hash' do
      let(:error_hash) { {} }

      it 'generates correct message' do
        expect(instance.message).to eq('An unknown error occurred. (no error code present)')
      end
    end
  end

  describe '#inspect' do
    it 'generates a correct object representation' do
      expect(instance.inspect).to eq('#<MicrosoftGraph::ApiError: "Uploaded fragment overlaps with existing data. (badRequest)\\nMicrosoft Graph API Request ID: request-id">')
    end

  end

end
