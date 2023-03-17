# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AttachmentsController, type: :request do
  include_context 'basic Knowledge Base'

  let(:object)        { create(:knowledge_base_answer, :draft, :with_attachment, category: category) }
  let(:attachment_id) { object.attachments.first.id }

  describe '#show' do
    it 'returns 404 when does not exist' do
      get '/api/v1/attachments/123'

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when no access', authenticated_as: -> { create(:agent) } do
      get "/api/v1/attachments/#{attachment_id}"

      expect(response).to have_http_status(:not_found)
    end

    it 'returns ok on success', authenticated_as: -> { create(:admin) } do
      get "/api/v1/attachments/#{attachment_id}"

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#destroy' do
    it 'returns 404 when does not exist' do
      delete '/api/v1/attachments/123'

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when no access', authenticated_as: -> { create(:agent) } do
      delete "/api/v1/attachments/#{attachment_id}"

      expect(response).to have_http_status(:not_found)
    end

    it 'returns ok on success', authenticated_as: -> { create(:admin) } do
      delete "/api/v1/attachments/#{attachment_id}"

      expect(response).to have_http_status(:ok)
    end
  end
end
