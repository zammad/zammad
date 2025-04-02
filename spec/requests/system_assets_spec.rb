# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'System Assets', type: :request do
  describe '#show' do
    it 'returns content for product logo' do
      allow(Service::SystemAssets::ProductLogo).to receive(:sendable_asset).and_return(
        Service::SystemAssets::SendableAsset.new(
          content:  'product_logo',
          filename: 'test',
          type:     'image/test'
        )
      )

      get '/api/v1/system_assets/product_logo/123'

      expect(response)
        .to have_http_status(:ok)
        .and(have_attributes(body: 'product_logo'))
    end

    it 'returns 404 for unknown item' do
      get '/api/v1/system_assets/example/123'

      expect(response).to have_http_status(:not_found)
    end
  end
end
