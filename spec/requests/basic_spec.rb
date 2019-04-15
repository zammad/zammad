require 'rails_helper'

RSpec.describe 'Basics', type: :request do

  describe 'request handling' do

    it 'does json requests' do

      # 404
      get '/not_existing_url', as: :json
      expect(response).to have_http_status(:not_found)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('No route matches [GET] /not_existing_url')

      # 401
      get '/api/v1/organizations', as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('authentication failed')

      # 422
      get '/tests/unprocessable_entity', as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('some error message')

      # 401
      get '/tests/not_authorized', as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('some error message')

      # 401
      get '/tests/ar_not_found', as: :json
      expect(response).to have_http_status(:not_found)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('some error message')

      # 500
      get '/tests/standard_error', as: :json
      expect(response).to have_http_status(:internal_server_error)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('some error message')

      # 422
      get '/tests/argument_error', as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('some error message')
    end

    it 'does html requests' do

      # 404
      get '/not_existing_url'
      expect(response).to have_http_status(:not_found)
      expect(response.body).to match(/<html/)
      expect(response.body).to match(%r{<title>404: Not Found</title>})
      expect(response.body).to match(%r{<h1>404: Requested resource was not found</h1>})
      expect(response.body).to match(%r{No route matches \[GET\] /not_existing_url})

      # 401
      get '/api/v1/organizations'
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to match(/<html/)
      expect(response.body).to match(%r{<title>401: Unauthorized</title>})
      expect(response.body).to match(%r{<h1>401: Unauthorized</h1>})
      expect(response.body).to match(/authentication failed/)

      # 422
      get '/tests/unprocessable_entity'
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match(/<html/)
      expect(response.body).to match(%r{<title>422: Unprocessable Entity</title>})
      expect(response.body).to match(%r{<h1>422: The change you wanted was rejected.</h1>})
      expect(response.body).to match(/some error message/)

      # 401
      get '/tests/not_authorized'
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to match(/<html/)
      expect(response.body).to match(%r{<title>401: Unauthorized</title>})
      expect(response.body).to match(%r{<h1>401: Unauthorized</h1>})
      expect(response.body).to match(/some error message/)

      # 401
      get '/tests/ar_not_found'
      expect(response).to have_http_status(:not_found)
      expect(response.body).to match(/<html/)
      expect(response.body).to match(%r{<title>404: Not Found</title>})
      expect(response.body).to match(%r{<h1>404: Requested resource was not found</h1>})
      expect(response.body).to match(/some error message/)

      # 500
      get '/tests/standard_error'
      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to match(/<html/)
      expect(response.body).to match(%r{<title>500: Something went wrong</title>})
      expect(response.body).to match(%r{<h1>500: We're sorry, but something went wrong.</h1>})
      expect(response.body).to match(/some error message/)

      # 422
      get '/tests/argument_error'
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match(/<html/)
      expect(response.body).to match(%r{<title>422: Unprocessable Entity</title>})
      expect(response.body).to match(%r{<h1>422: The change you wanted was rejected.</h1>})
      expect(response.body).to match(/some error message/)
    end
  end

end
