# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::TwoFactor::GetMethodConfiguration do
  subject(:service) { described_class.new(user:, method_name:) }

  let(:user)        { create(:agent) }
  let(:method_name) { 'authenticator_app' }
  let(:enabled)     { true }

  before do
    Setting.set('two_factor_authentication_method_authenticator_app', enabled)
  end

  context 'when method does not exist' do
    let(:method_name) { 'nonsense' }

    it 'raises an error' do
      expect { service.execute }
        .to raise_error(Exceptions::UnprocessableEntity)
    end
  end

  context 'when method is configured' do
    let(:user_preference) { create(:user_two_factor_preference, :authenticator_app, user:) }

    before { user_preference }

    context 'when method is enabled' do
      it 'returns configuration' do
        expect(service.execute).to eq(user_preference.configuration)
      end
    end

    context 'when method is not enabled' do
      let(:enabled) { false }

      it 'returns configuration' do
        expect(service.execute).to eq(user_preference.configuration)
      end
    end
  end

  context 'when method is not configured' do
    it 'returns nil' do
      expect(service.execute).to be_nil
    end
  end
end
