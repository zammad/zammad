# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User', authenticated_as: :admin, current_user_id: 1, type: :request do
  let(:agent)              { create(:agent) }
  let(:admin)              { create(:admin) }
  let(:two_factor_pref)    { create(:user_two_factor_preference, :authenticator_app, user: agent) }
  let(:two_factor_enabled) { true }

  before do
    Setting.set('two_factor_authentication_method_authenticator_app', two_factor_enabled)
  end

  describe 'DELETE /users/:id/admin_two_factor/remove_authentication_method' do
    it 'deletes record' do
      two_factor_pref

      expect { delete "/api/v1/users/#{agent.id}/admin_two_factor/remove_authentication_method", params: { method: 'authenticator_app' }, as: :json }
        .to change { agent.two_factor_preferences.count }
        .to(0)
    end
  end

  describe 'DELETE /users/:id/admin_two_factor/remove_all_authentication_methods' do
    it 'deletes records' do
      two_factor_pref

      # add disabled two factor method
      create(:user_two_factor_preference, :security_keys, user: agent)

      expect { delete "/api/v1/users/#{agent.id}/admin_two_factor/remove_all_authentication_methods", as: :json }
        .to change { agent.two_factor_preferences.count }
        .to(0)
    end
  end

  describe 'GET /users/:id/admin_two_factor/enabled_authentication_methods' do
    context 'with disabled authenticator app method' do
      let(:two_factor_enabled) { false }

      it 'response is blank' do
        two_factor_pref

        get "/api/v1/users/#{agent.id}/admin_two_factor/enabled_authentication_methods", as: :json

        expect(json_response).to be_blank
      end
    end

    it 'lists enabled method' do
      get "/api/v1/users/#{agent.id}/admin_two_factor/enabled_authentication_methods", as: :json

      expect(json_response.first).to eq({
                                          'method'     => 'authenticator_app',
                                          'configured' => false,
                                          'default'    => false,
                                        })
    end

    it 'lists in-use method as configured' do
      two_factor_pref

      get "/api/v1/users/#{agent.id}/admin_two_factor/enabled_authentication_methods", as: :json

      expect(json_response.first).to eq({
                                          'method'     => 'authenticator_app',
                                          'configured' => true,
                                          'default'    => true,
                                        })
    end
  end
end
