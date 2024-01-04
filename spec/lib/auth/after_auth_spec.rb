# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth::AfterAuth do
  let(:customer)            { create(:customer, roles: [role]) }
  let(:role)                { create(:role, name: '2FA') }
  let(:session)             { { authentication_type: authentication_type } }
  let(:authentication_type) { 'password' }

  context 'when after auth is triggered' do
    context 'with third-party login' do
      let(:authentication_type) { 'omniauth' }

      it 'returns nil' do
        expect(described_class.run(customer, session)).to be_nil
      end
    end

    context 'with no enforcing roles' do
      it 'returns nil' do
        expect(described_class.run(customer, session)).to be_nil
      end
    end

    context 'with enforcing roles' do
      before do
        Setting.set('two_factor_authentication_enforce_role_ids', [role.id])
        Setting.set('two_factor_authentication_method_authenticator_app', true)
      end

      it 'returns the after auth type' do
        expect(described_class.run(customer, session)).to eq({ type: 'TwoFactorConfiguration', data: {} })
      end
    end
  end
end
