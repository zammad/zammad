# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Google Email', time_zone: 'Europe/London', type: :system do
  let(:client_id)     { SecureRandom.uuid }
  let(:client_secret) { SecureRandom.urlsafe_base64(40) }
  let(:callback_url)  { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{Rails.configuration.api_path}/external_credentials/google/callback" }

  context 'without an existing app configuration' do
    before do
      visit '#channels/google'
    end

    it 'creates a new app configuration' do
      find('.btn--success', text: 'Connect Google App').click

      in_modal do
        fill_in 'client_id', with: client_id
        fill_in 'client_secret', with: client_secret

        check_input_field_value('callback_url', callback_url)

        click_on 'Submit'
      end

      expect(ExternalCredential.last).to have_attributes(
        name:        'google',
        credentials: include(client_id:, client_secret:)
      )
    end
  end

  context 'with an existing app configuration' do
    let(:external_credential) { create(:google_credential) }

    before do
      external_credential
    end

    # includes initial setup
    context 'when editing an account' do
      let(:channel) do
        create(:google_channel, active: false)
          .tap do |channel|
            channel.options[:inbound][:options].merge! folder: folder1, keep_on_server: true
            channel.save!
          end
      end

      let(:state)   { Ticket::State.find_by(name: 'open') }
      let(:folder1) { 'Folder1' }
      let(:folder2) { 'Folder2' }

      before do
        channel

        allow_any_instance_of(Channel).to receive(:refresh_xoauth2!).and_return(true)
        allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok' })
      end

      context 'when editing a freshly added account' do
        before do
          visit "#channels/google/#{channel.id}"
        end

        context 'when no emails exist' do
          before do
            allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok', content_messages: 0 })
          end

          it 'does not display archive dialog but saves channel' do
            in_modal do
              fill_in 'options::folder', with: folder2
              click_on 'Submit'
            end

            expect(channel.reload).to have_attributes(
              active:  true,
              options: include(inbound: include(options: include(folder: folder2)))
            )
          end
        end

        context 'when some emails exist' do
          before do
            allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok', content_messages: 123 })
          end

          it 'displays inbound configuration dialog' do
            visit "#channels/google/#{channel.id}"

            in_modal do
              fill_in 'options::folder', with: folder2
              set_select_field_label('options::keep_on_server', 'no')

              click_on 'Submit'
            end

            in_modal do
              set_select_field_value('options::archive_state_id', state.id.to_s)
              set_date_field_value('options::archive_before', '12/01/2024')
              click_on 'Submit'
            end

            expect(channel.reload).to have_attributes(
              active:  true,
              options: include(
                inbound: include(
                  options: include(
                    folder:           folder2,
                    keep_on_server:   false,
                    archive:          true,
                    archive_state_id: state.id.to_s,
                    archive_before:   '2024-12-01T08:00:00.000Z'
                  ),
                ),
              ),
            )
          end
        end
      end

      context 'when editing an existing channel' do
        before do
          channel.options[:inbound][:options]
            .merge!(archive: true, archive_state_id: state.id.to_s, archive_before: '2024-12-01T08:00:00.000Z')
          channel.save!

          allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok', content_messages: 0 })
          visit '#channels/google'
          find('.js-editInbound', text: 'Edit').click
        end

        it 'displays inbound configuration dialog' do
          in_modal do
            expect(page).to have_field('options::folder', with: folder1)
            check_select_field_value('options::keep_on_server', 'true')

            fill_in 'options::folder', with: folder2
            set_select_field_label('options::keep_on_server', 'no')

            click_on 'Submit'
          end

          in_modal do
            check_switch_field_value('options::archive', true)
            check_select_field_value('options::archive_state_id', state.id.to_s)
            check_date_field_value('options::archive_before', '12/01/2024')

            click '.js-switch'

            click_on 'Submit'
          end

          expect(channel.reload).to have_attributes(
            active:  false,
            options: include(
              inbound: include(
                options: include(
                  folder:           folder2,
                  keep_on_server:   false,
                  archive:          false,
                  archive_state_id: state.id.to_s,
                  archive_before:   '2024-12-01T08:00:00.000Z'
                ),
              ),
            ),
          )
        end
      end
    end
  end
end
