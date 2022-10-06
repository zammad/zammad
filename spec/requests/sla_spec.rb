# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'SLAs', type: :request do

  let(:admin) do
    create(:admin)
  end

  describe 'request handling' do

    it 'does index sla with nobody' do
      get '/api/v1/slas', as: :json
      expect(response).to have_http_status(:forbidden)

      expect(json_response).to be_a(Hash)
      expect(json_response['error']).to eq('Authentication required')
    end

    it 'does index sla with admin' do
      authenticated_as(admin)
      get '/api/v1/slas', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
      expect(json_response.count).to eq(0)

      get '/api/v1/slas?expand=true', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Array)
      expect(json_response).to be_truthy
      expect(json_response.count).to eq(0)

      get '/api/v1/slas?full=true', as: :json
      expect(response).to have_http_status(:ok)
      expect(json_response).to be_a(Hash)
      expect(json_response).to be_truthy
      expect(json_response['record_ids']).to be_truthy
      expect(json_response['record_ids']).to be_blank
      expect(json_response['assets']).to be_truthy
      expect(json_response['assets']['Calendar']).to be_present
      expect(json_response['assets']).to be_present
    end
  end

end
