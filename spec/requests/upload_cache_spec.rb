# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'UploadCache', type: :request do

  let(:user)    { create(:customer) }
  let(:form_id) { 1337 }
  let(:upload_cache) { UploadCache.new(form_id) }

  # required for adding items to the Store
  before { UserInfo.current_user_id = 1 }

  before { authenticated_as(user) }

  describe '/upload_caches/:id' do

    context 'for POST requests' do

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
    end
  end

  describe '/upload_caches/:id/items/:store_id' do

    context 'for DELETE requests' do

      before do
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
    end
  end
end
