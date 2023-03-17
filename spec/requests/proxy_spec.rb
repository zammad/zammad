# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Settings > System > Network', required_envs: %w[CI_PROXY_URL CI_PROXY_USER CI_PROXY_PASSWORD], type: :request do

  let(:group) { create(:group) }
  let!(:admin) do
    create(:admin, groups: [Group.lookup(name: 'Users'), group])
  end
  let(:proxy)          { ENV['CI_PROXY_URL'] }
  let(:proxy_username) { ENV['CI_PROXY_USER'] }
  let(:proxy_password) { ENV['CI_PROXY_PASSWORD'] }
  let(:valid_params) do
    {
      proxy:          proxy,
      proxy_username: proxy_username,
      proxy_password: proxy_password
    }
  end

  describe 'request handling' do

    it 'does proxy settings - valid params' do
      authenticated_as(admin)

      post '/api/v1/proxy', params: valid_params, as: :json

      expect(json_response['result']).to eq('success')
    end

    context 'when proxy settings uses invalid config' do

      it 'with invalid proxy' do
        authenticated_as(admin)
        params = valid_params.merge({ proxy: 'invalid_proxy' })

        post '/api/v1/proxy', params: params, as: :json

        expect(json_response['result']).to eq('failed')
      end

      it 'with unknown proxy' do
        authenticated_as(admin)
        params = valid_params.merge({ proxy_password: 'proxy.example.com:3128' })

        post '/api/v1/proxy', params: params, as: :json

        expect(json_response['result']).to eq('failed')

      end

      it 'with invalid proxy username' do
        authenticated_as(admin)
        params = valid_params.merge({ proxy_password: 'invalid_username' })

        post '/api/v1/proxy', params: params, as: :json

        expect(json_response['result']).to eq('failed')

      end

      it 'with invalid proxy password' do
        authenticated_as(admin)
        params = valid_params.merge({ proxy_password: 'invalid_password' })

        post '/api/v1/proxy', params: params, as: :json

        expect(json_response['result']).to eq('failed')
      end
    end

  end
end
