# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::TwoFactor::InitiateMethodConfiguration do
  subject(:service) { described_class.new(user:, method_name:) }

  let(:user) { create(:agent) }

  context 'when the given method exists' do
    let(:method_name) { 'authenticator_app' }

    context 'when the given method is not enabled' do
      it 'raises error' do
        expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'The two-factor authentication method is not enabled.')
      end
    end

    context 'when given method is enabled' do
      before do
        Setting.set('two_factor_authentication_method_authenticator_app', true)
      end

      it 'returns secret and provisioning_uri' do
        expect(service.execute).to include(:secret).and include(:provisioning_uri)
      end
    end
  end

  context 'when the given method does not exist' do
    let(:method_name) { 'nonsense' }

    it 'raises error' do
      expect { service.execute }.to raise_error(Exceptions::UnprocessableEntity, 'The given two-factor method does not exist.')
    end
  end
end
