# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Microsoft365 channel API endpoints', type: :request do
  let(:admin)                 { create(:admin) }
  let!(:microsoft365_channel) { create(:microsoft365_channel) }

  describe 'DELETE /api/v1/channels_microsoft365', authenticated_as: :admin do
    context 'without a email address relation' do
      let(:params) do
        {
          id: microsoft365_channel.id
        }
      end

      it 'responds 200 OK' do
        delete '/api/v1/channels_microsoft365', params: params, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'microsoft365 channel deleted' do
        expect { delete '/api/v1/channels_microsoft365', params: params, as: :json }.to change(Channel, :count).by(-1)
      end
    end

    context 'with a email address relation' do
      let(:params) do
        {
          id: microsoft365_channel.id
        }
      end

      before do
        create(:email_address, channel: microsoft365_channel)
      end

      it 'responds 200 OK' do
        delete '/api/v1/channels_microsoft365', params: params, as: :json

        expect(response).to have_http_status(:ok)
      end

      it 'microsoft365 channel and related email address deleted' do
        expect { delete '/api/v1/channels_microsoft365', params: params, as: :json }.to change(Channel, :count).by(-1).and change(EmailAddress, :count).by(-1)
      end
    end
  end
end
