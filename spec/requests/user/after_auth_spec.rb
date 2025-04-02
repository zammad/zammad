# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User after auth endpoint', authenticated_as: :customer, type: :request do
  before do
    setting if defined?(setting)

    # Do a "real" login to get a valid session.
    params = {
      fingerprint: fingerprint,
      username:    customer.login,
      password:    password
    }

    post '/api/v1/signin', params: params, as: :json

    get '/api/v1/users/after_auth', as: :json
  end

  let(:password)    { SecureRandom.urlsafe_base64(20) }
  let(:fingerprint) { SecureRandom.urlsafe_base64(40) }
  let(:customer)    { create(:customer, roles: [role], password: password) }
  let(:role)        { create(:role, name: '2FA') }

  context 'when no after auth module should be present' do
    it 'returns nil' do
      expect(json_response).to be_nil
    end
  end

  context 'when a after auth module should be present' do
    let(:setting) do
      Setting.set('two_factor_authentication_enforce_role_ids', [role.id])
      Setting.set('two_factor_authentication_method_authenticator_app', true)
    end

    it 'returns the after auth information' do
      expect(json_response).to eq({ 'data' => {}, 'type' => 'TwoFactorConfiguration' })
    end
  end
end
