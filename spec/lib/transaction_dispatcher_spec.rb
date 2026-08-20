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

  describe '.execute_single_backend' do
    let(:user)     { create(:agent) }
    let(:observed) { {} }
    let(:backend) do
      probe = observed

      Class.new do
        def initialize(*); end

        define_method(:perform) do
          probe[:user_id]        = UserInfo.current_user_id
          probe[:system_context] = UserInfo.system_context?
          probe[:assets_user_id] = UserInfo.assets.current_user_id
          probe[:assets_agent]   = UserInfo.assets.agent?
        end
      end
    end

    before { UserInfo.current_user_id = user.id }

    # The assets matter as much as the user id: a backend that kept the caller's asset context
    # would still render unredacted data, which is the leak this guards against.
    it 'runs the backend without a user context', :aggregate_failures do
      described_class.execute_single_backend(backend, {}, {})

      expect(observed).to include(user_id: nil, assets_user_id: nil, assets_agent: false)
    end

    # The system context marks the whole unit of work, so a backend dispatched from background
    # work keeps it - otherwise the reset here would silently unprivilege everything that runs
    # after the first dispatch, including the caller.
    it 'keeps the system context of the caller', :aggregate_failures do
      UserInfo.with_system_context do
        described_class.execute_single_backend(backend, {}, {})

        expect(UserInfo).to be_system_context
      end

      expect(observed).to include(system_context: true)
    end

    it 'does not raise when the backend does' do
      allow(Rails.logger).to receive(:error)

      failing_backend = Class.new do
        def initialize(*); end

        def perform
          raise 'error'
        end
      end

      expect { described_class.execute_single_backend(failing_backend, {}, {}) }.not_to raise_error
    end
  end
end
