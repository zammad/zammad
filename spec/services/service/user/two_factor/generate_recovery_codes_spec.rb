# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::TwoFactor::GenerateRecoveryCodes, current_user_id: 1 do
  subject(:service) { described_class.new(user:, force:) }

  let(:user) { create(:agent) }

  context 'when recovery codes not enabled' do
    before { Setting.set('two_factor_authentication_recovery_codes', false) }

    context 'when force flag is not given' do
      let(:force) { false }

      it 'returns falsey value' do
        expect(service.execute).to be_falsey
      end

      it 'does not generate recovery codes' do
        expect_any_instance_of(Auth::TwoFactor::RecoveryCodes).not_to receive(:generate)

        service.execute
      end

      it 'does not change user recovery codes' do
        expect { service.execute }
          .not_to change { user.reload.two_factor_preferences.recovery_codes&.configuration }
      end
    end

    context 'when force flag is given' do
      let(:force) { true }

      it 'returns falsey value' do
        expect(service.execute).to be_falsey
      end

      it 'does not generate recovery codes' do
        expect_any_instance_of(Auth::TwoFactor::RecoveryCodes).not_to receive(:generate)

        service.execute
      end

      it 'does not change user recovery codes' do
        expect { service.execute }
          .not_to change { user.reload.two_factor_preferences.recovery_codes&.configuration }
      end
    end
  end

  context 'when user already has recover codes' do
    before do
      Setting.set('two_factor_authentication_recovery_codes', true)
      create(:user_two_factor_preference, :recovery_codes, user: user)
      user.reload
    end

    context 'when force flag is not given' do
      let(:force) { false }

      it 'returns falsey value' do
        expect(service.execute).to be_falsey
      end

      it 'does not generate recovery codes' do
        expect_any_instance_of(Auth::TwoFactor::RecoveryCodes).not_to receive(:generate)

        service.execute
      end

      it 'does not change user recovery codes' do
        expect { service.execute }
          .not_to change { user.reload.two_factor_preferences.recovery_codes&.configuration }
      end
    end

    context 'when force flag is given' do
      let(:force) { true }

      it 'returns new codes' do
        expect(service.execute)
          .to include(be_a(String))
      end

      it 'generates recovery codes' do
        expect_any_instance_of(Auth::TwoFactor::RecoveryCodes).to receive(:generate)

        service.execute
      end

      it 'updates user recovery codes' do
        expect { service.execute }
          .to change { user.reload.two_factor_preferences.recovery_codes&.configuration }
      end
    end
  end

  context 'when user does not have recovery codes' do
    before { Setting.set('two_factor_authentication_recovery_codes', true) }

    context 'when force flag is not given' do
      let(:force) { false }

      it 'returns new codes' do
        expect(service.execute).to include(be_a(String))
      end

      it 'generates recovery codes' do
        expect_any_instance_of(Auth::TwoFactor::RecoveryCodes).to receive(:generate)

        service.execute
      end

      it 'updates user recovery codes' do
        expect { service.execute }
          .to change { user.reload.two_factor_preferences.recovery_codes&.configuration }
      end
    end

    context 'when force flag is given' do
      let(:force) { true }

      it 'returns new codes' do
        expect(service.execute).to include(be_a(String))
      end

      it 'generates recovery codes' do
        expect_any_instance_of(Auth::TwoFactor::RecoveryCodes).to receive(:generate)

        service.execute
      end

      it 'updates user recovery codes' do
        expect { service.execute }
          .to change { user.reload.two_factor_preferences.recovery_codes&.configuration }
      end
    end
  end
end
