# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
        let(:channel) do
          create(:email_channel).tap do |c|
            c.options['inbound']['options']['password'] = 'stored_password'
            c.options['outbound']['options'] ||= {}
            c.options['outbound']['options']['password'] = 'stored_password'
            c.save!
          end
        end
        let(:channel_id)          { channel.id }
        let!(:email_address)      { create(:email_address, channel: channel) }
        let(:group_email_address) { true }

        context 'without masked passwords' do
          let(:update_params) do
            params.deep_merge(
              inbound:  { options: { password: 'updated_password' } },
              outbound: { options: { password: 'updated_password' } },
            )
          end

          it 'updates channel' do
            post '/api/v1/channels_email_verify', params: update_params
            expect(response).to have_http_status(:ok)

            expect(channel.reload.group.email_address_id).to eq(email_address.id)
            expect(channel.reload.options[:inbound][:options][:password]).to eq('updated_password')
            expect(channel.reload.options[:outbound][:options][:password]).to eq('updated_password')
          end
        end

        context 'with masked passwords' do
          let(:update_params) do
            params.deep_merge(
              inbound:  { options: { password: SensitiveParamsHelper::SENSITIVE_MASK } },
              outbound: { options: { password: SensitiveParamsHelper::SENSITIVE_MASK } },
            )
          end

          it 'updates channel' do
            post '/api/v1/channels_email_verify', params: update_params
            expect(response).to have_http_status(:ok)

            expect(channel.reload.group.email_address_id).to eq(email_address.id)
            expect(channel.reload.options[:inbound][:options][:password]).to eq('stored_password')
            expect(channel.reload.options[:outbound][:options][:password]).to eq('stored_password')
          end
        end
      end
    end
  end

  describe 'POST /api/v1/channels_email_inbound', aggregate_failures: true, authenticated_as: :admin do
    let(:params) do
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
    let(:channel_id) { nil }

    before do
      allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok' })
    end

    context 'when creating new inbound configuration' do
      it 'tests inbound connection' do
        post '/api/v1/channels_email_inbound', params: params
        expect(response).to have_http_status(:ok)
        expect(json_response).to include('result' => 'ok')
      end
    end

    context 'when updating existing channel' do
      let(:channel) do
        create(:email_channel).tap do |c|
          c.options['inbound']['options']['password'] = 'stored_password'
          c.save!
        end
      end
      let(:channel_id) { channel.id }

      context 'with new password' do
        let(:update_params) do
          params.merge(
            channel_id: channel_id,
            options:    params[:options].merge(password: 'new_password')
          )
        end

        it 'uses new password for testing' do
          allow(EmailHelper::Probe).to receive(:inbound).with(
            hash_including(
              options: hash_including(password: 'new_password')
            )
          ).and_return({ result: 'ok' })

          post '/api/v1/channels_email_inbound', params: update_params
          expect(response).to have_http_status(:ok)
          expect(EmailHelper::Probe).to have_received(:inbound).with(
            hash_including(
              options: hash_including(password: 'new_password')
            )
          )
        end
      end

      context 'with masked password' do
        let(:update_params) do
          params.merge(
            channel_id: channel_id,
            options:    params[:options].merge(password: SensitiveParamsHelper::SENSITIVE_MASK)
          )
        end

        it 'uses stored password for testing' do
          allow(EmailHelper::Probe).to receive(:inbound).with(
            hash_including(
              options: hash_including(password: 'stored_password')
            )
          ).and_return({ result: 'ok' })

          post '/api/v1/channels_email_inbound', params: update_params
          expect(response).to have_http_status(:ok)
          expect(EmailHelper::Probe).to have_received(:inbound).with(
            hash_including(
              options: hash_including(password: 'stored_password')
            )
          )
        end
      end

      context 'when response contains sensitive data' do
        before do
          allow(EmailHelper::Probe).to receive(:inbound).and_return(
            {
              result:   'ok',
              settings: {
                adapter: 'imap',
                options: {
                  password: 'sensitive_password',
                  host:     'test.example.com',
                  port:     993
                }
              }
            }
          )
        end

        it 'masks password in response' do
          post '/api/v1/channels_email_inbound', params: params
          expect(response).to have_http_status(:ok)
          expect(json_response).to include('result' => 'ok')
          # Password should be masked
          expect(json_response.dig('settings', 'options', 'password')).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
        end
      end
    end
  end

  describe 'POST /api/v1/channels_email_outbound', aggregate_failures: true, authenticated_as: :admin do
    let(:params) do
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
    let(:email) { 'test@example.com' }
    let(:channel_id) { nil }

    before do
      allow(EmailHelper::Probe).to receive(:outbound).and_return({ result: 'ok' })
    end

    context 'when creating new outbound configuration' do
      it 'tests outbound connection' do
        post '/api/v1/channels_email_outbound', params: params.merge(email: email)
        expect(response).to have_http_status(:ok)
        expect(json_response).to include('result' => 'ok')
      end
    end

    context 'when updating existing channel' do
      let(:channel) do
        create(:email_channel).tap do |c|
          c.options['outbound'] ||= {}
          c.options['outbound']['options'] ||= {}
          c.options['outbound']['options']['password'] = 'stored_password'
          c.save!
        end
      end
      let(:channel_id) { channel.id }

      context 'with new password' do
        let(:update_params) do
          params.merge(
            channel_id: channel_id,
            email:      email,
            options:    params[:options].merge(password: 'new_password')
          )
        end

        it 'uses new password for testing' do
          allow(EmailHelper::Probe).to receive(:outbound).with(
            hash_including(
              options: hash_including(password: 'new_password')
            ),
            email
          ).and_return({ result: 'ok' })

          post '/api/v1/channels_email_outbound', params: update_params
          expect(response).to have_http_status(:ok)
          expect(EmailHelper::Probe).to have_received(:outbound).with(
            hash_including(
              options: hash_including(password: 'new_password')
            ),
            email
          )
        end
      end

      context 'with masked password' do
        let(:update_params) do
          params.merge(
            channel_id: channel_id,
            email:      email,
            options:    params[:options].merge(password: SensitiveParamsHelper::SENSITIVE_MASK)
          )
        end

        it 'uses stored password for testing' do
          allow(EmailHelper::Probe).to receive(:outbound).with(
            hash_including(
              options: hash_including(password: 'stored_password')
            ),
            email
          ).and_return({ result: 'ok' })

          post '/api/v1/channels_email_outbound', params: update_params
          expect(response).to have_http_status(:ok)
          expect(EmailHelper::Probe).to have_received(:outbound).with(
            hash_including(
              options: hash_including(password: 'stored_password')
            ),
            email
          )
        end
      end

      context 'when response contains sensitive data' do
        before do
          allow(EmailHelper::Probe).to receive(:outbound).and_return(
            {
              result:   'ok',
              settings: {
                adapter: 'smtp',
                options: {
                  password: 'sensitive_password',
                  host:     'smtp.example.com',
                  port:     465
                }
              }
            }
          )
        end

        it 'masks password in response' do
          post '/api/v1/channels_email_outbound', params: params.merge(email: email)
          expect(response).to have_http_status(:ok)
          expect(json_response).to include('result' => 'ok')
          # Password should be masked
          expect(json_response.dig('settings', 'options', 'password')).to eq(SensitiveParamsHelper::SENSITIVE_MASK)
        end
      end
    end
  end
end
