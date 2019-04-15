require 'rails_helper'

RSpec.describe 'SLAs', type: :request do

  let(:admin_user) do
    create(:admin_user)
  end

  describe 'request handling' do

    it 'does index sla with nobody' do
      get '/api/v1/slas', as: :json
      expect(response).to have_http_status(:unauthorized)

      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response['error']).to eq('authentication failed')
    end

    it 'does index sla with admin' do
      authenticated_as(admin_user)
      get '/api/v1/slas', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response).to be_truthy
      expect(json_response.count).to eq(0)

      get '/api/v1/slas?expand=true', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Array)
      expect(json_response).to be_truthy
      expect(json_response.count).to eq(0)

      get '/api/v1/slas?full=true', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a_kind_of(Hash)
      expect(json_response).to be_truthy
      expect(json_response['record_ids']).to be_truthy
      expect(json_response['record_ids']).to be_blank
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Calendar']).to be_present
      expect(json_response['assets']).to be_present
    end
  end

end
