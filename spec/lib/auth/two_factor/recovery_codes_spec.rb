# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::TwoFactor::RecoveryCodes, current_user_id: 1 do
  subject(:instance) { described_class.new(user) }

  let(:user) { create(:user) }

  shared_examples 'responding to provided instance method' do |method|
    it "responds to '.#{method}'" do
      expect(instance).to respond_to(method)
    end
  end

  it_behaves_like 'responding to provided instance method', :verify
  it_behaves_like 'responding to provided instance method', :generate
  it_behaves_like 'responding to provided instance method', :exists?
  it_behaves_like 'responding to provided instance method', :enabled?
  it_behaves_like 'responding to provided instance method', :method_name
  it_behaves_like 'responding to provided instance method', :related_setting_name
  it_behaves_like 'responding to provided instance method', :create_user_config
  it_behaves_like 'responding to provided instance method', :destroy_user_config

  describe '#verify' do
    let(:current_codes) { instance.generate }
    let(:current_hashed_codes) { user.reload.two_factor_preferences.recovery_codes.configuration[:codes] }
    let(:code)                 { current_codes.first }

    before do
      current_codes
      current_hashed_codes
    end

    context 'when code is correct' do
      it 'returns true' do
        expect(instance.verify(code)[:verified]).to be(true)
      end

      it 'removes code from list' do
        verify_result = instance.verify(code)
        expect(verify_result['codes']).not_to include(code)
      end
    end

    context 'when code is incorrect' do
      let(:code) { 'incorrect' }

      before do
        current_codes
        current_hashed_codes
      end

      it 'returns false' do
        expect(instance.verify(code)[:verified]).to be(false)
      end

      it 'current code list is untouched' do
        instance.verify(code)

        expect(user.reload.two_factor_preferences.recovery_codes.configuration[:codes]).to eq(current_hashed_codes)
      end
    end
  end

  describe '#generate' do
    it 'codes will be generated' do
      expect(instance.generate.length).to eq(described_class.const_get(:NUMBER_OF_CODES))
    end

    it 'codes have the correct length' do
      expect(instance.generate.first.length).to eq(described_class.const_get(:CODE_LENGTH))
    end

    it 'codes are saved in two factor preferences' do
      instance.generate

      expect(user.reload.two_factor_preferences.recovery_codes.configuration[:codes].length).to eq(described_class.const_get(:NUMBER_OF_CODES))
    end

    context 'when codes already exist' do
      let(:current_codes)        { instance.generate }
      let(:current_hashed_codes) { user.reload.two_factor_preferences.recovery_codes.configuration[:codes] }

      before do
        current_codes
        current_hashed_codes
      end

      it 'codes are saved in two factor preferences' do
        instance.generate

        expect(user.reload.two_factor_preferences.recovery_codes.configuration[:codes]).not_to be(current_hashed_codes)
      end
    end
  end

  describe '#exists?' do
    let(:two_factor_pref_recovery_codes) do
      create(:user_two_factor_preference, :authenticator_app,
             user:          user,
             method:        'recovery_codes',
             configuration: {})
    end

    context 'when recovery codes are present' do
      before { two_factor_pref_recovery_codes }

      it 'returns true' do
        expect(instance.exists?).to be(true)
      end
    end

    context 'when recovery codes are not present' do
      it 'returns false' do
        expect(instance.exists?).to be(false)
      end
    end
  end
end
