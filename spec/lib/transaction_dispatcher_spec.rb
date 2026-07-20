# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TransactionDispatcher do
  describe '.perform' do
    context 'when a sync backend is configured but its class does not exist' do
      before do
        Setting.create!(
          title:       'Bogus transaction backend',
          name:        '0999_transaction_backend_bogus',
          area:        'Transaction::Backend::Sync',
          description: 'Test-only backend referencing a missing class.',
          options:     {},
          state:       'Transaction::DoesNotExist',
          frontend:    false,
        )
      end

      it 'skips the missing backend and logs an error instead of raising', :aggregate_failures do
        allow(Rails.logger).to receive(:error)

        expect { described_class.perform({}) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(%r{Transaction::DoesNotExist})
      end
    end
  end
end
