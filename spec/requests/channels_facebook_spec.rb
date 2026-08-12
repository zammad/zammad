# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Facebook channel API endpoints', :aggregate_failures, authenticated_as: :admin, type: :request do
  let(:admin) { create(:admin) }

  let(:channel) do
    create(:channel, area: 'Facebook::Account', options: {
             adapter: 'facebook',
             auth:    { access_token: 'user-token' },
             pages:   [
               { id: '1', name: 'Page 1', access_token: 'page-1-token' },
               { id: '2', name: 'Page 2', access_token: 'page-2-token' },
             ],
           })
  end

  describe 'GET /api/v1/channels_facebook' do
    it 'masks the access tokens' do
      channel && get('/api/v1/channels_facebook', as: :json)

      expect(json_response.dig('assets', 'Channel', channel.id.to_s, 'options'))
        .to include(
          'auth'  => { 'access_token' => SensitiveParamsHelper::SENSITIVE_MASK },
          'pages' => [
            { 'id' => '1', 'name' => 'Page 1', 'access_token' => SensitiveParamsHelper::SENSITIVE_MASK },
            { 'id' => '2', 'name' => 'Page 2', 'access_token' => SensitiveParamsHelper::SENSITIVE_MASK },
          ]
        )
    end
  end

  describe 'POST /api/v1/channels_facebook/:id' do
    # the channel dialog posts back the masked options it received via assets
    let(:params) do
      {
        id:      channel.id,
        options: {
          adapter: 'facebook',
          auth:    { access_token: SensitiveParamsHelper::SENSITIVE_MASK },
          pages:   [
            { id: '1', name: 'Page 1', access_token: SensitiveParamsHelper::SENSITIVE_MASK },
            { id: '2', name: 'Page 2', access_token: SensitiveParamsHelper::SENSITIVE_MASK },
          ],
          sync:    { pages: { '1' => { group_id: Group.first.id } } },
        },
      }
    end

    it 'restores the stored access tokens instead of persisting the mask' do
      post "/api/v1/channels_facebook/#{channel.id}", params: params, as: :json

      expect(response).to have_http_status(:ok)
      expect(channel.reload.options).to include(
        'auth'  => { 'access_token' => 'user-token' },
        'pages' => [
          { 'id' => '1', 'name' => 'Page 1', 'access_token' => 'page-1-token' },
          { 'id' => '2', 'name' => 'Page 2', 'access_token' => 'page-2-token' },
        ]
      )
    end

    it 'masks the access tokens in the response' do
      post "/api/v1/channels_facebook/#{channel.id}", params: params, as: :json

      expect(json_response['options']).to include(
        'auth'  => { 'access_token' => SensitiveParamsHelper::SENSITIVE_MASK },
        'pages' => [
          { 'id' => '1', 'name' => 'Page 1', 'access_token' => SensitiveParamsHelper::SENSITIVE_MASK },
          { 'id' => '2', 'name' => 'Page 2', 'access_token' => SensitiveParamsHelper::SENSITIVE_MASK },
        ]
      )
    end

    it 'restores the stored access tokens if the posted pages are in a different order' do
      params[:options][:pages] = params[:options][:pages].reverse

      post "/api/v1/channels_facebook/#{channel.id}", params: params, as: :json

      expect(channel.reload.options['pages']).to eq(
        [
          { 'id' => '2', 'name' => 'Page 2', 'access_token' => 'page-2-token' },
          { 'id' => '1', 'name' => 'Page 1', 'access_token' => 'page-1-token' },
        ]
      )
    end

    it 'stores the changed sync configuration' do
      post "/api/v1/channels_facebook/#{channel.id}", params: params, as: :json

      expect(channel.reload.options['sync']).to eq({ 'pages' => { '1' => { 'group_id' => Group.first.id } } })
    end
  end
end
