# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Import mode', :aggregate_failures, type: :request do
  let(:agent) { create(:agent) }
  let(:admin) { create(:admin) }

  shared_examples 'refusing the request' do
    it 'returns 403 Forbidden' do
      get '/api/v1/users/me', as: :json

      expect(response).to have_http_status(:forbidden)
      expect(json_response).to include('error' => 'Maintenance mode enabled!')
    end
  end

  shared_examples 'serving the request' do |user_name|
    it 'returns the current user' do
      get '/api/v1/users/me', as: :json

      expect(response).to have_http_status(:ok)
      expect(json_response).to include('id' => send(user_name).id)
    end
  end

  context 'with an already open session' do
    before do
      authenticated_as(user, via: :browser)
      Setting.set('import_mode', true)
    end

    context 'with an agent' do
      let(:user) { agent }

      include_examples 'refusing the request'
    end

    context 'with an administrator' do
      let(:user) { admin }

      include_examples 'serving the request', :admin
    end
  end

  context 'with an impersonated session' do
    before do
      authenticated_as(switching_user, via: :browser)
      get "/api/v1/sessions/switch/#{agent.id}", as: :json
      Setting.set('import_mode', true)
    end

    context 'when switched from an administrator with maintenance permission' do
      let(:switching_user) { admin }

      include_examples 'serving the request', :agent
    end

    context 'when switched from an administrator without maintenance permission' do
      let(:switching_user) { create(:user, roles: [create(:role, permission_names: %w[admin.user ticket.agent])]) }

      include_examples 'refusing the request'
    end
  end

  context 'with token authentication' do
    before do
      Setting.set('import_mode', true)
      authenticated_as(user, token: create(:token, action: 'api', user_id: user.id))
    end

    context 'with an agent' do
      let(:user) { agent }

      include_examples 'refusing the request'
    end

    context 'with an administrator' do
      let(:user) { admin }

      include_examples 'serving the request', :admin
    end
  end

  context 'with HTTP basic authentication' do
    before do
      Setting.set('import_mode', true)
      authenticated_as(user)
    end

    context 'with an agent' do
      let(:user) { agent }

      include_examples 'refusing the request'
    end

    context 'with an administrator' do
      let(:user) { admin }

      include_examples 'serving the request', :admin
    end
  end
end
