# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'OAuth', type: :request do

  describe 'request handling' do

    it 'does o365 - start' do
      post '/auth/microsoft_office365'
      expect(response).to have_http_status(:found)
      expect(response.body).to include('https://login.microsoftonline.com/common/oauth2/v2.0/authorize')
      expect(response.body).to include('redirect_uri=http%3A%2F%2Fzammad.example.com%2Fauth%2Fmicrosoft_office365%2Fcallback')
      expect(response.body).to include('scope=openid+User.Read+Contacts.Read')
      expect(response.body).to include('response_type=code')
    end

    it 'does o365 - callback' do
      get '/auth/microsoft_office365/callback?code=1234&state=1234'
      expect(response).to have_http_status(:found)
      expect(response.body).to include('302 Moved')
    end

    it 'does auth failure' do
      get '/auth/failure?message=123&strategy=some_provider'
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('<title>422: Unprocessable Entity</title>')
      expect(response.body).to include('<h1>422: The change you wanted was rejected.</h1>')
      expect(response.body).to include('<div>Message from some_provider: 123</div>')
    end
  end

end
