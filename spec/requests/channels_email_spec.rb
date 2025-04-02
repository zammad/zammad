# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Email channel API endpoints', type: :request do
  let(:admin) { create(:admin) }

  describe 'POST /api/v1/channels_email_group/ID', aggregate_failures: true, authenticated_as: :admin do
    let(:channel) { create(:email_channel) }
    let(:email_address)       { create(:email_address, channel: channel) }
    let(:group)               { create(:group) }
    let(:group_email_address) { true }
    let(:params) do
      {
        group_id:            group.id,
        group_email_address: group_email_address,
      }
    end

    it 'updates channel group' do
      post "/api/v1/channels_email_group/#{channel.id}", params: params
      expect(response).to have_http_status(:ok)

      expect(channel.reload.group_id).to eq(group.id)
    end
  end

  describe 'POST /api/v1/channels_email/verify/ID', aggregate_failures: true, authenticated_as: :admin do
    let(:group) { create(:group) }
    let(:params) do
      {
        inbound:                inbound_params,
        outbound:               outbound_params,
        meta:                   meta_params,
        group_id:               group_id,
        group_email_address:    group_email_address,
        group_email_address_id: group_email_address_id,
        channel_id:             channel_id,
      }
    end

    let(:inbound_params) do
      {
        adapter: 'imap',
        options: {
          host:             'nonexisting.host.local',
          port:             993,
          ssl:              'ssl',
          user:             'some@example.com',
          password:         'xyz',
          ssl_verify:       true,
          archive:          true,
          archive_before:   '2025-01-01T00.00.000Z',
          archive_state_id: Ticket::State.find_by(name: 'open').id
        },
      }
    end
    let(:outbound_params) do
      {
        adapter: 'smtp',
        options: {
          host:                 'nonexisting.host.local',
          port:                 465,
          start_tls:            true,
          user:                 'some@example.com',
          password:             'xyz',
          ssl_verify:           true,
          ssl:                  true,
          domain:               'example.com',
          enable_starttls_auto: true,
        },
      }
    end
    let(:meta_params) do
      {
        realname: 'Testing',
        email:    'some@example.com',
        password: 'xyz',
      }
    end
    let(:group_id)               { nil }
    let(:group_email_address)    { false }
    let(:group_email_address_id) { nil }
    let(:channel_id)             { nil }

    before do
      Channel.where(area: 'Email::Account').each(&:destroy)

      allow(EmailHelper::Verify).to receive(:email).and_return({ result: 'ok' })
    end

    it 'creates new channel' do
      post '/api/v1/channels_email_verify', params: params
      expect(response).to have_http_status(:ok)

      expect(Channel.last).to have_attributes(
        group_id: Group.first.id,
        options:  include(
          inbound: include(
            options: include(
              archive:          'true',
              archive_before:   '2025-01-01T00.00.000Z',
              archive_state_id: Ticket::State.find_by(name: 'open').id.to_s,
            )
          )
        )
      )
    end

    context 'when group email address handling is used' do
      let(:group) { create(:group, email_address: nil) }
      let(:group_id) { group.id }

      context 'when group email address should be set' do
        let(:group_email_address) { true }

        it 'creates new channel' do
          post '/api/v1/channels_email_verify', params: params
          expect(response).to have_http_status(:ok)

          expect(Channel.last.group.email_address_id).to eq(EmailAddress.find_by(channel_id: Channel.last.id).id)
        end
      end

      context 'when group email address should not be set' do
        let(:group_email_address) { false }

        it 'creates new channel' do
          post '/api/v1/channels_email_verify', params: params
          expect(response).to have_http_status(:ok)

          expect(Channel.last.group.email_address_id).to be_nil
        end
      end

      context 'when channel is already created' do
        let(:channel) { create(:email_channel) }
        let(:channel_id)          { channel.id }
        let!(:email_address)      { create(:email_address, channel: channel) }
        let(:group_email_address) { true }

        it 'updates channel' do
          post '/api/v1/channels_email_verify', params: params
          expect(response).to have_http_status(:ok)

          expect(channel.reload.group.email_address_id).to eq(email_address.id)
        end
      end
    end
  end
end
