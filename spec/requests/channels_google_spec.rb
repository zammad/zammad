# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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

  describe 'POST /api/v1/channels_google_inbound/ID' do
    let(:channel) { create(:google_channel) }
    let(:group)   { create(:group) }

    before do
      Channel.where(area: 'Google::Account').each(&:destroy)
      allow_any_instance_of(Channel).to receive(:refresh_xoauth2!).and_return(true)
      allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok' })
    end

    it 'does not update inbound options of the channel' do
      expect do
        post "/api/v1/channels_google_inbound/#{channel.id}", params: { group_id: group.id, options: { folder: 'SomeFolder', keep_on_server: 'true' } }
      end.not_to change(channel, :updated_at)
    end
  end

  describe 'POST /api/v1/channels_google_verify/ID', aggregate_failures: true, authenticated_as: :admin do
    let(:channel)        { create(:google_channel) }
    let(:group)          { create(:group, email_address_id: nil) }
    let(:email_address)  { create(:email_address, channel: channel) }

    before do
      Channel.where(area: 'Google::Account').each(&:destroy)

      email_address
    end

    it 'updates inbound options of the channel' do
      post "/api/v1/channels_google_verify/#{channel.id}", params: { group_id: group.id, options: { folder: 'SomeFolder', keep_on_server: 'true', archive: 'true', archive_before: '2025-01-01T00.00.000Z', archive_state_id: Ticket::State.find_by(name: 'open').id } }
      expect(response).to have_http_status(:ok)

      channel.reload

      expect(channel).to have_attributes(
        group_id: group.id,
        options:  include(
          inbound: include(
            options: include(
              folder:           'SomeFolder',
              keep_on_server:   'true',
              archive:          'true',
              archive_before:   '2025-01-01T00.00.000Z',
              archive_state_id: Ticket::State.find_by(name: 'open').id.to_s,
            )
          )
        )
      )
    end

    context 'when group email address is used' do
      it 'updates the group email address' do
        post "/api/v1/channels_google_verify/#{channel.id}", params: { group_email_address: true, group_id: group.id, options: { folder_id: 'AAMkAD=', keep_on_server: 'true' } }

        expect(response).to have_http_status(:ok)
        expect(channel.group.reload.email_address_id).to eq(email_address.id)
      end

      context 'when group email should not be changed' do
        it 'does not update the group email address' do
          post "/api/v1/channels_google_verify/#{channel.id}", params: { group_email_address: false, group_id: group.id, options: { folder_id: 'AAMkAD=', keep_on_server: 'true' } }

          expect(response).to have_http_status(:ok)
          expect(channel.reload.group.email_address_id).to be_nil
        end
      end

      context 'when group email should be changed to specific email address' do
        let(:email_address2) { create(:email_address, channel: channel) }

        it 'updates the group email address' do
          post "/api/v1/channels_google_verify/#{channel.id}", params: { group_email_address: true, group_email_address_id: email_address2.id, group_id: group.id, options: { folder_id: 'AAMkAD=', keep_on_server: 'true' } }

          expect(response).to have_http_status(:ok)
          expect(channel.reload.group.email_address_id).to eq(email_address2.id)
        end
      end
    end
  end
end
