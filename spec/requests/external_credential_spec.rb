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

    it 'does external_credential app_verify with admin - facebook' do
      authenticated_as(admin_user)
      post '/api/v1/external_credentials/facebook/app_verify', as: :json
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No application_id param!')

      VCR.use_cassette('request/external_credentials/facebook/app_verify_invalid_credentials_with_not_created') do
        post '/api/v1/external_credentials/facebook/app_verify', params: { application_id: 123, application_secret: 123 }, as: :json
      end
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')

      create(:external_credential, { name: 'facebook', credentials: { application_id: 123, application_secret: 123 } })
      VCR.use_cassette('request/external_credentials/facebook/app_verify_invalid_credentials_with_created') do
        post '/api/v1/external_credentials/facebook/app_verify', as: :json
      end
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
    end

    it 'does external_credential app_verify with admin - twitter' do
      authenticated_as(admin_user)
      post '/api/v1/external_credentials/twitter/app_verify', as: :json
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No consumer_key param!')

      VCR.use_cassette('request/external_credentials/twitter/app_verify_invalid_credentials_with_not_created') do
        post '/api/v1/external_credentials/twitter/app_verify', params: { consumer_key: 123, consumer_secret: 123, oauth_token: 123, oauth_token_secret: 123 }, as: :json
      end
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('401 Authorization Required')

      create(:external_credential, { name: 'twitter', credentials: { consumer_key: 123, consumer_secret: 123, oauth_token: 123, oauth_token_secret: 123 } })
      VCR.use_cassette('request/external_credentials/twitter/app_verify_invalid_credentials_with_created') do
        post '/api/v1/external_credentials/twitter/app_verify', as: :json
      end
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('401 Authorization Required')
    end

    it 'does link_account app_verify with admin - facebook' do
      authenticated_as(admin_user)
      get '/api/v1/external_credentials/facebook/link_account', as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No facebook app configured!')

      get '/api/v1/external_credentials/facebook/link_account', params: { application_id: 123, application_secret: 123 }, as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No facebook app configured!')

      create(:external_credential, { name: 'facebook', credentials: { application_id: 123, application_secret: 123 } })

      VCR.use_cassette('request/external_credentials/facebook/link_account_with_invalid_credential') do
        get '/api/v1/external_credentials/facebook/link_account', as: :json
      end
      expect(response).to have_http_status(500)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
    end

    it 'does link_account app_verify with admin - twitter' do
      authenticated_as(admin_user)
      get '/api/v1/external_credentials/twitter/link_account', as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No twitter app configured!')

      get '/api/v1/external_credentials/twitter/link_account', params: { consumer_key: 123, consumer_secret: 123, oauth_token: 123, oauth_token_secret: 123 }, as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No twitter app configured!')

      create(:external_credential, { name: 'twitter', credentials: { consumer_key: 123, consumer_secret: 123, oauth_token: 123, oauth_token_secret: 123 } })
      VCR.use_cassette('request/external_credentials/twitter/link_account_with_invalid_credential') do
        get '/api/v1/external_credentials/twitter/link_account', as: :json
      end
      expect(response).to have_http_status(500)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('401 Authorization Required')
    end

    it 'does external_credential callback with admin - facebook' do
      authenticated_as(admin_user)
      get '/api/v1/external_credentials/facebook/callback', as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No facebook app configured!')

      get '/api/v1/external_credentials/facebook/callback', params: { application_id: 123, application_secret: 123 }, as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No facebook app configured!')

      create(:external_credential, { name: 'facebook', credentials: { application_id: 123, application_secret: 123 } })
      VCR.use_cassette('request/external_credentials/facebook/callback_invalid_credentials') do
        get '/api/v1/external_credentials/facebook/callback', as: :json
      end
      expect(response).to have_http_status(500)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('type: OAuthException, code: 101, message: Error validating application. Cannot get application info due to a system error. [HTTP 400]')
    end

    it 'does external_credential callback with admin - twitter' do
      authenticated_as(admin_user)
      get '/api/v1/external_credentials/twitter/callback', as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No twitter app configured!')

      get '/api/v1/external_credentials/twitter/callback', params: { consumer_key: 123, consumer_secret: 123 }, as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No twitter app configured!')

      create(:external_credential, { name: 'twitter', credentials: { consumer_key: 123, consumer_secret: 123 } })
      get '/api/v1/external_credentials/twitter/callback', as: :json
      expect(response).to have_http_status(422)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No request_token for session found!')

      #request.session[:oauth_token] = 'some_token'
      #get '/api/v1/external_credentials/twitter/callback', as: :json
      #expect(response).to have_http_status(422)
      #expect(json_response).to be_a_kind_of(Hash)
      #expect(json_response['error']).to eq('Invalid oauth_token given!')
    end

    it 'does external_credential app_verify with admin and different permissions' do
      authenticated_as(admin_user)

      create(:external_credential, { name: 'twitter', credentials: { consumer_key: 123, consumer_secret: 123 } })
      VCR.use_cassette('request/external_credentials/twitter/app_verify_twitter') do
        post '/api/v1/external_credentials/twitter/app_verify', as: :json
      end
      expect(response).to have_http_status(200)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('401 Authorization Required')

      permission = Permission.find_by(name: 'admin.channel_twitter')
      permission.active = false
      permission.save!

      post '/api/v1/external_credentials/twitter/app_verify', as: :json
      expect(response).to have_http_status(401)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('Not authorized (user)!')

      create(:external_credential, { name: 'facebook', credentials: { application_id: 123, application_secret: 123 } })
      VCR.use_cassette('request/external_credentials/facebook/app_verify_facebook') do
        post '/api/v1/external_credentials/facebook/app_verify', as: :json
      end
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
