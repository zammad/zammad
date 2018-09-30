require 'rails_helper'

RSpec.describe 'ExternalCredentials', type: :request do

  let(:admin_user) do
    create(:admin_user)
  end

  describe 'request handling' do

    it 'does external_credential index with nobody' do
      get '/api/v1/external_credentials', as: :json
      expect(response).to have_http_status(401)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does external_credential app_verify with nobody' do
      post '/api/v1/external_credentials/facebook/app_verify', as: :json
      expect(response).to have_http_status(401)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does link_account app_verify with nobody' do
      get '/api/v1/external_credentials/facebook/link_account', as: :json
      expect(response).to have_http_status(401)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does external_credential callback with nobody' do
      get '/api/v1/external_credentials/facebook/callback', as: :json
      expect(response).to have_http_status(401)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does external_credential index with admin' do
      authenticated_as(admin_user)
      get '/api/v1/external_credentials', as: :json
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response).to be_truthy
      expect(json_response.count).to eq(0)

      get '/api/v1/external_credentials?expand=true', as: :json
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response).to be_truthy
      expect(json_response.count).to eq(0)
    end

    it 'does external_credential app_verify with admin' do
      authenticated_as(admin_user)
      post '/api/v1/external_credentials/facebook/app_verify', as: :json
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No facebook app configured!')

      create(:external_credential, name: 'facebook')

      post '/api/v1/external_credentials/facebook/app_verify', as: :json
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
    end

    it 'does link_account app_verify with admin' do
      authenticated_as(admin_user)
      get '/api/v1/external_credentials/facebook/link_account', as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No facebook app configured!')

      create(:external_credential, name: 'facebook')

      get '/api/v1/external_credentials/facebook/link_account', as: :json
      expect(response).to have_http_status(500)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
    end

    it 'does external_credential callback with admin' do
      authenticated_as(admin_user)
      get '/api/v1/external_credentials/facebook/callback', as: :json
      expect(response).to have_http_status(500)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No such account')

      create(:external_credential, name: 'facebook')

      get '/api/v1/external_credentials/facebook/callback', as: :json
      expect(response).to have_http_status(500)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
    end

    it 'does external_credential app_verify with admin and different permissions' do
      authenticated_as(admin_user)

      create(:external_credential, name: 'twitter')

      post '/api/v1/external_credentials/twitter/app_verify', as: :json
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('400 Bad Request')

      permission = Permission.find_by(name: 'admin.channel_twitter')
      permission.active = false
      permission.save!

      post '/api/v1/external_credentials/twitter/app_verify', as: :json
      expect(response).to have_http_status(401)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized (user)!')

      create(:external_credential, name: 'facebook')

      post '/api/v1/external_credentials/facebook/app_verify', as: :json
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')

      permission = Permission.find_by(name: 'admin.channel_facebook')
      permission.active = false
      permission.save!

      post '/api/v1/external_credentials/facebook/app_verify', as: :json
      expect(response).to have_http_status(401)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized (user)!')
    end

  end
end
