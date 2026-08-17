# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'UploadCache', type: :request do

  let(:user)         { create(:customer) }
  let(:auth)         { user }
  let(:form_id)      { SecureRandom.uuid }
  let(:upload_cache) { UploadCache.new(form_id) }

  describe '/upload_caches/:id' do

    context 'for POST requests' do
      before do
        UserInfo.current_user_id = user.id
        authenticated_as(auth)
      end

      it 'adds items to UploadCache' do
        params = {
          File: fixture_file_upload('upload/hello_world.txt', 'text/plain')
        }
        post "/api/v1/upload_caches/#{form_id}", params: params

        expect(response).to have_http_status(:ok)
      end

      it 'detects Content-Type for binary uploads' do
        params = {
          File: fixture_file_upload('upload/hello_world.txt', 'application/octet-stream')
        }
        post "/api/v1/upload_caches/#{form_id}", params: params

        expect(Store.last.preferences['Content-Type']).to eq('text/plain')
      end
    end

    context 'for DELETE requests' do

      before do
        UserInfo.current_user_id = user.id
        authenticated_as(auth)

        2.times do |iteration|
          upload_cache.add(
            data:        "Can't touch this #{iteration}",
            filename:    'keep.txt',
            preferences: {
              'Content-Type' => 'text/plain',
            },
          )
        end
      end

      it 'removes all form_id UploadCache items' do
        expect do
          delete "/api/v1/upload_caches/#{form_id}", as: :json
        end.to change(upload_cache, :attachments).to([])
      end

      context 'with invalid user' do
        let(:auth) { create(:customer) }

        it 'returns forbidden' do
          delete "/api/v1/upload_caches/#{form_id}", as: :json

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe '/upload_caches/:id/items/:store_id' do

    context 'for DELETE requests' do

      before do
        UserInfo.current_user_id = user.id
        authenticated_as(auth)

        upload_cache.add(
          data:        "Can't touch this",
          filename:    'keep.txt',
          preferences: {
            'Content-Type' => 'text/plain',
          },
        )
      end

      it 'removes a UploadCache item by given store id' do

        store_id = upload_cache.attachments.first.id
        delete "/api/v1/upload_caches/#{form_id}/items/#{store_id}", as: :json

        expect(Store.exists?(store_id)).to be(false)
      end

      context 'with invalid user' do
        let(:auth) { create(:customer) }

        it 'returns forbidden' do
          store_id = upload_cache.attachments.first.id
          delete "/api/v1/upload_caches/#{form_id}/items/#{store_id}", as: :json

          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe 'DELETE /upload_caches/:id (mixed-owner cache)' do
    let(:owner)       { create(:customer) }
    let(:other_owner) { create(:customer) }

    before do
      UploadCache.new(form_id).add(
        data:          'owner data',
        filename:      'owner.txt',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: owner.id,
      )
      UploadCache.new(form_id).add(
        data:          'other data',
        filename:      'other.txt',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: other_owner.id,
      )
    end

    it 'forbids partial owner from destroying mixed-owner cache' do
      authenticated_as(owner)
      delete "/api/v1/upload_caches/#{form_id}", as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /upload_caches/:id/items/:store_id (mixed-owner cache)' do
    let(:owner)       { create(:customer) }
    let(:other_owner) { create(:customer) }

    before do
      UploadCache.new(form_id).add(
        data:          'owner data',
        filename:      'owner.txt',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: owner.id,
      )
      UploadCache.new(form_id).add(
        data:          'other data',
        filename:      'other.txt',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: other_owner.id,
      )
    end

    it 'forbids partial owner from removing other users file' do
      authenticated_as(owner)
      other_file = UploadCache.new(form_id).attachments(created_by_id: nil).find { |a| a.created_by_id == other_owner.id }
      delete "/api/v1/upload_caches/#{form_id}/items/#{other_file.id}", as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids partial owner from removing their own file too' do
      authenticated_as(owner)
      own_file = UploadCache.new(form_id).attachments(created_by_id: owner.id).first
      delete "/api/v1/upload_caches/#{form_id}/items/#{own_file.id}", as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it 'leaves every file in a mixed-owner cache untouched after a forbidden removal attempt' do
      authenticated_as(owner)
      own_file = UploadCache.new(form_id).attachments(created_by_id: owner.id).first
      delete "/api/v1/upload_caches/#{form_id}/items/#{own_file.id}", as: :json

      expect(UploadCache.new(form_id).attachments(created_by_id: nil).map(&:created_by_id)).to contain_exactly(owner.id, other_owner.id)
    end
  end
end
