# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

  describe '#show (Ticket::Article)', authenticated_as: -> { agent } do
    let(:group)    { create(:group) }
    let(:customer) { create(:customer) }
    let(:agent)    { create(:agent, groups: [group]) }
    let(:ticket)   { create(:ticket, group: group, customer: customer) }

    let(:public_article) { create(:ticket_article, ticket: ticket, internal: false) }
    let(:public_store) do
      create(:store,
             object:      'Ticket::Article',
             o_id:        public_article.id,
             data:        'public data',
             filename:    'public.txt',
             preferences: { 'Content-Type' => 'text/plain' })
    end

    let(:internal_article) { create(:ticket_article, :internal_note, ticket: ticket) }
    let(:internal_store) do
      create(:store,
             object:      'Ticket::Article',
             o_id:        internal_article.id,
             data:        'secret data',
             filename:    'secret.txt',
             preferences: { 'Content-Type' => 'text/plain' })
    end

    it 'customer cannot download internal article attachment' do
      authenticated_as(customer)
      get "/api/v1/attachments/#{internal_store.id}"
      expect(response).to have_http_status(:not_found)
    end

    it 'agent downloads internal article attachment' do
      get "/api/v1/attachments/#{internal_store.id}"
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
