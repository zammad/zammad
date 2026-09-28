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

    # A published answer's attachment is downloadable without any session at all, so a deactivated
    #   knowledge base has to stop it here as well.
    #   https://github.com/zammad/zammad/issues/6338
    context 'when the knowledge base is inactive' do
      let(:object) { create(:knowledge_base_answer, :published, :with_attachment, category: category) }

      before { knowledge_base.update! active: false }

      it 'returns 404 for a guest' do
        get "/api/v1/attachments/#{attachment_id}"

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for a customer', authenticated_as: -> { create(:customer) } do
        get "/api/v1/attachments/#{attachment_id}"

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for an editor', authenticated_as: -> { create(:admin) } do
        get "/api/v1/attachments/#{attachment_id}"

        expect(response).to have_http_status(:not_found)
      end
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

    it 'streams the attachment content', :aggregate_failures do
      get "/api/v1/attachments/#{public_store.id}"
      expect(response.body).to eq('public data')
      expect(response.headers['Content-Length']).to eq('public data'.bytesize.to_s)
    end

    context 'with file system storage' do
      before { Setting.set('storage_provider', 'File') }

      after { Store::Provider::File.delete(public_store.store_file.sha) }

      it 'streams the attachment content', :aggregate_failures do
        get "/api/v1/attachments/#{public_store.id}"
        expect(public_store.store_file.provider).to eq('File')
        expect(response.body).to eq('public data')
        expect(response.headers['Content-Length']).to eq('public data'.bytesize.to_s)
      end
    end

    context 'when the stored content is missing' do
      shared_examples 'responding with not found' do
        before { allow(Rails.logger).to receive(:error) }

        it 'returns 404 for the download and logs the missing content', :aggregate_failures do
          get "/api/v1/attachments/#{image_store.id}"
          expect(response).to have_http_status(:not_found)
          expect(Rails.logger).to have_received(:error).with(%r{Content of Store::File #{image_store.store_file_id} .* is missing})
        end

        it 'returns 404 for the preview' do
          get "/api/v1/attachments/#{image_store.id}?preview=1"
          expect(response).to have_http_status(:not_found)
        end
      end

      let(:image_store) do
        create(:store,
               object:      'Ticket::Article',
               o_id:        public_article.id,
               data:        Rails.root.join('test/data/upload/upload2.jpg').binread,
               filename:    'image.jpg',
               preferences: { 'Content-Type' => 'image/jpg' })
      end

      context 'with database storage' do
        before { Store::Provider::DB.delete(image_store.store_file.sha) }

        include_examples 'responding with not found'
      end

      context 'with file system storage' do
        before do
          Setting.set('storage_provider', 'File')
          Store::Provider::File.delete(image_store.store_file.sha)
        end

        include_examples 'responding with not found'
      end
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

  describe '#create' do
    let(:owner) { create(:customer) }
    let(:attacker) { create(:customer) }
    let(:form_id)  { SecureRandom.uuid }

    it 'allows upload to own empty cache' do
      authenticated_as(owner)
      params = { File: fixture_file_upload('upload/hello_world.txt', 'text/plain'), form_id: form_id }

      post '/api/v1/attachments', params: params

      expect(response).to have_http_status(:ok)
    end

    it 'forbids upload to foreign populated cache' do
      UploadCache.new(form_id).add(
        filename:      'victim.txt',
        data:          'victim data',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: owner.id,
      )

      authenticated_as(attacker)
      params = { File: fixture_file_upload('upload/hello_world.txt', 'text/plain'), form_id: form_id }

      post '/api/v1/attachments', params: params

      expect(response).to have_http_status(:not_found)
    end

    it 'forbids upload without a form_id' do
      authenticated_as(owner)
      params = { File: fixture_file_upload('upload/hello_world.txt', 'text/plain') }

      post '/api/v1/attachments', params: params

      expect(response).to have_http_status(:not_found)
    end
  end
end
