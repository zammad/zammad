# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Google channel API endpoints', type: :request do
  let(:admin)           { create(:admin) }
  let!(:google_channel) { create(:google_channel) }

  describe 'DELETE /api/v1/channels_google', authenticated_as: :admin do
    context 'without a email address relation' do
      let(:params) do
        {
          id: google_channel.id
        }
      end

      it 'responds 200 OK' do
        delete '/api/v1/channels_google', params: params, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'google channel deleted' do
        expect { delete '/api/v1/channels_google', params: params, as: :json }.to change(Channel, :count).by(-1)
      end
    end

    context 'with a email address relation' do
      let(:params) do
        {
          id: google_channel.id
        }
      end

      before do
        create(:email_address, channel: google_channel)
      end

      it 'responds 200 OK' do
        delete '/api/v1/channels_google', params: params, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'google channel and related email address deleted' do
        expect { delete '/api/v1/channels_google', params: params, as: :json }.to change(Channel, :count).by(-1).and change(EmailAddress, :count).by(-1)
      end
    end
  end
end
