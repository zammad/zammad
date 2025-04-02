# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > Microsoft 365 Graph Email', time_zone: 'Europe/London', type: :system do
  let(:client_id)     { SecureRandom.uuid }
  let(:client_secret) { SecureRandom.urlsafe_base64(40) }
  let(:client_tenant) { SecureRandom.uuid }
  let(:callback_url)  { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{Rails.configuration.api_path}/external_credentials/microsoft_graph/callback" }

  context 'without an existing app configuration' do
    before do
      visit '#channels/microsoft_graph'
    end

    it 'creates a new app configuration' do
      find('.btn--success', text: 'Connect Microsoft 365 App').click

      in_modal do
        fill_in 'client_id', with: client_id
        fill_in 'client_secret', with: client_secret
        fill_in 'client_tenant', with: client_tenant

        check_input_field_value('callback_url', callback_url)
        check_copy_to_clipboard_text('callback_url', callback_url)

        click_on 'Submit'
      end

      expect(ExternalCredential.last).to have_attributes(
        name:        'microsoft_graph',
        credentials: include(
          client_id:     client_id,
          client_secret: client_secret,
          client_tenant: client_tenant,
        )
      )
    end
  end

  context 'with an existing app configuration' do
    let(:external_credential) { create(:microsoft_graph_credential) }

    before do
      external_credential
    end

    context 'when adding an account' do
      let(:shared_mailbox) { Faker::Internet.unique.email }

      before do
        visit '#channels/microsoft_graph'
      end

      it 'shows mailbox type dialog' do
        find('.btn--success', text: 'Add Account').click

        in_modal do
          check_select_field_value('mailbox_type', 'user')

          expect(page).to have_no_css('[name="shared_mailbox"]')

          set_select_field_value('mailbox_type', 'shared')

          click_on 'Authenticate'

          expect(page).to have_validation_message_for('[name="shared_mailbox"]')

          set_input_field_value('shared_mailbox', shared_mailbox)
        end
      end
    end

    context 'when editing an account' do
      let(:channel)    { create(:microsoft_graph_channel, group: group1, inbound_options: { 'folder_id' => folder_id1, 'keep_on_server' => true }, active: false) }
      let(:group1)     { create(:group) }
      let(:group2)     { create(:group) }
      let(:state)      { Ticket::State.find_by(name: 'open') }
      let(:folder_id1) { Base64.strict_encode64(Faker::Crypto.unique.sha256) }
      let(:folder_id2) { Base64.strict_encode64(Faker::Crypto.unique.sha256) }

      let(:folders) do
        [
          {
            'id'           => folder_id1,
            'displayName'  => Faker::Lorem.unique.word,
            'childFolders' => [],
          },
          {
            'id'           => folder_id2,
            'displayName'  => Faker::Lorem.unique.word,
            'childFolders' => [],
          },
        ]
      end

      before do
        channel && group2

        allow_any_instance_of(Channel).to receive(:refresh_xoauth2!).and_return(true)
        allow_any_instance_of(MicrosoftGraph).to receive(:get_message_folders_tree).and_return(folders)
        allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok' })
      end

      context 'when editing a freshly added account' do
        before do
          visit "#channels/microsoft_graph/#{channel.id}"
        end

        context 'when no emails exist' do
          before do
            allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok', content_messages: 0 })
          end

          it 'does not display archive dialog but saves channel' do
            in_modal do
              set_tree_select_value('group_id', group1.id.to_s)
              set_tree_select_value('options::folder_id', folder_id2)
              click_on 'Save'
            end

            expect(channel.reload).to have_attributes(
              active:  true,
              options: include(inbound: include(options: include(folder_id: folder_id2)))
            )
          end
        end

        context 'when some emails exist' do
          before do
            allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok', content_messages: 123 })
          end

          it 'displays inbound configuration dialog' do
            visit "#channels/microsoft_graph/#{channel.id}"

            in_modal do
              check_tree_select_field_value('group_id', group1.id.to_s)
              check_tree_select_field_value('options::folder_id', folder_id1)
              check_select_field_value('options::keep_on_server', 'true')

              set_tree_select_value('group_id', group2.id.to_s)
              set_tree_select_value('options::folder_id', folder_id2)
              set_select_field_label('options::keep_on_server', 'no')

              click_on 'Save'
            end

            in_modal do
              set_select_field_value('options::archive_state_id', state.id.to_s)
              set_date_field_value('options::archive_before', '12/01/2024')
              click_on 'Submit'
            end

            expect(channel.reload).to have_attributes(
              group_id: group2.id,
              active:   true,
              options:  include(
                inbound: include(
                  options: include(
                    folder_id:        folder_id2,
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
          visit '#channels/microsoft_graph'
          find('.js-editInbound', text: 'Edit').click
        end

        it 'displays inbound configuration dialog' do
          in_modal do
            check_tree_select_field_value('group_id', group1.id.to_s)
            check_tree_select_field_value('options::folder_id', folder_id1)
            check_select_field_value('options::keep_on_server', 'true')

            set_tree_select_value('group_id', group2.id.to_s)
            set_tree_select_value('options::folder_id', folder_id2)
            set_select_field_label('options::keep_on_server', 'no')

            click_on 'Save'
          end

          in_modal do
            check_switch_field_value('options::archive', true)
            check_select_field_value('options::archive_state_id', state.id.to_s)
            check_date_field_value('options::archive_before', '12/01/2024')

            click '.js-switch'

            click_on 'Submit'
          end

          expect(channel.reload).to have_attributes(
            group_id: group2.id,
            active:   false,
            options:  include(
              inbound: include(
                options: include(
                  folder_id:        folder_id2,
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

    context 'when editing destination group' do
      let(:channel) { create(:microsoft_graph_channel, group: group1, active: false) }
      let(:group1)  { create(:group) }
      let(:group2)  { create(:group) }
      let(:folders) { [] }

      before do
        channel && group2

        allow_any_instance_of(Channel).to receive(:refresh_xoauth2!).and_return(true)
        allow_any_instance_of(MicrosoftGraph).to receive(:get_message_folders_tree).and_return(folders)
        allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok' })

        visit '#channels/microsoft_graph'

        find('.js-channelGroupChange', text: group1.name).click
      end

      it 'displays destination group dialog' do
        in_modal do
          check_tree_select_field_value('group_id', group1.id.to_s)
          set_tree_select_value('group_id', group2.id.to_s)

          click_on 'Submit'
        end

        expect(channel.reload).to have_attributes(group_id: group2.id)
      end
    end

    context 'when toggling an account' do
      let(:channel) { create(:microsoft_graph_channel, active: false) }

      before do
        channel

        visit '#channels/microsoft_graph'
      end

      it 'switches channel between enabled and disabled state' do
        find('.js-enable', text: 'Enable').click

        expect(channel.reload.active).to be(true)

        find('.js-disable', text: 'Disable').click

        expect(channel.reload.active).to be(false)
      end
    end

    context 'when deleting an account' do
      let(:channel)       { create(:microsoft_graph_channel, active: false) }
      let(:email_address) { create(:email_address, email: channel.options.dig('inbound', 'options', 'user'), channel: channel) }

      before do
        channel && email_address

        visit '#channels/microsoft_graph'

        find('.js-delete', text: 'Delete').click
      end

      it 'destroys the channel and the associated email address' do
        in_modal do
          click_on 'Yes'
        end

        expect { channel.reload }.to raise_error(ActiveRecord::RecordNotFound)

        expect(page).to have_content('Notice: Unassigned email addresses, assign them to a channel or delete them.')

        find('.js-emailAddressDelete').click

        in_modal do
          click_on 'Delete'
        end

        expect { email_address.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when being redirected by a successful auth flow' do
      let(:channel)   { create(:microsoft_graph_channel, active: false) }
      let(:group)     { create(:group) }
      let(:folder_id) { Base64.strict_encode64(Faker::Crypto.unique.sha256) }

      let(:folders) do
        [
          {
            'id'           => folder_id,
            'displayName'  => Faker::Lorem.unique.word,
            'childFolders' => [],
          },
        ]
      end

      before do
        channel && group

        allow_any_instance_of(Channel).to receive(:refresh_xoauth2!).and_return(true)
        allow_any_instance_of(MicrosoftGraph).to receive(:get_message_folders_tree).and_return(folders)
        allow(EmailHelper::Probe).to receive(:inbound).and_return({ result: 'ok' })

        visit "#channels/microsoft_graph/#{channel.id}"
      end

      it 'displays inbound configuration dialog' do
        in_modal do
          check_tree_select_field_value('group_id', Group.first.id.to_s)
          check_tree_select_field_value('options::folder_id', '')

          set_tree_select_value('group_id', group.id.to_s)
          set_tree_select_value('options::folder_id', folder_id)
          set_select_field_label('options::keep_on_server', 'yes')

          click_on 'Save'
        end

        expect(channel.reload).to have_attributes(
          group_id: group.id,
          options:  include(
            inbound: include(
              options: include(
                folder_id:      folder_id,
                keep_on_server: true,
              ),
            ),
          ),
        )
      end
    end

    context 'when being redirected with a wrong user' do
      let(:email_address) { Faker::Internet.unique.email }
      let(:channel)       { create(:microsoft_graph_channel, microsoft_user: email_address, active: false) }

      before do
        visit "#channels/microsoft_graph/error/user_mismatch/channel/#{channel.id}"
      end

      it 'displays user mismatch dialog' do
        in_modal do
          expect(page).to have_content('The entered user for reauthentication differs from the user that was used for setting up your Microsoft365 channel initially.')
          expect(page).to have_content('To avoid fetching an incorrect Microsoft365 mailbox, the reauthentication process was aborted.')
          expect(page).to have_content('Please start the reauthentication again and enter the correct credentials.')
          expect(page).to have_content("Current User: #{email_address}")

          click_on 'Close'
        end
      end
    end

    context 'when being redirected with an email address already in use' do
      let(:email_address) { Faker::Internet.unique.email }

      before do
        visit "#channels/microsoft_graph/error/duplicate_email_address/param/#{CGI.escapeURIComponent(email_address)}"
      end

      it 'displays duplicate email address dialog' do
        in_modal do
          expect(page).to have_content("The email address #{email_address} is already in use by another account.")

          click_on 'Close'
        end
      end
    end

    context 'when the API throws an error' do
      let(:channel) { create(:microsoft_graph_channel, active: false) }

      let(:error) do
        {
          message: 'The mailbox is either inactive, soft-deleted, or is hosted on-premise.',
          code:    'MailboxNotEnabledForRESTAPI',
        }
      end

      before do
        channel

        allow_any_instance_of(Channel).to receive(:refresh_xoauth2!).and_return(true)
        allow_any_instance_of(MicrosoftGraph).to receive(:get_message_folders_tree).and_raise(MicrosoftGraph::ApiError, error)

        visit '#channels/microsoft_graph'

        find('.js-editInbound', text: 'Edit').click
      end

      it 'displays original error message and a helpful hint' do
        in_modal do
          expect(page).to have_content("#{error[:message]} (#{error[:code]})")
          expect(page).to have_content('Did you verify that the user has access to the mailbox? Or consider removing this channel and switch to using a different mailbox type.')

          click_on 'Cancel & Go Back'
        end
      end
    end
  end

  def check_copy_to_clipboard_text(field_name, clipboard_text)
    find(".js-copy[data-target-field='#{field_name}']").click

    # Add a temporary text input element to the page, so we can paste the clipboard text into it and compare the value.
    #   Programmatic clipboard management requires extra browser permissions and does not work in all of them.
    page.execute_script "$('<input name=\"clipboard_#{field_name}\" type=\"text\" class=\"form-control\">').insertAfter($('input[name=#{field_name}]'));"

    input_field = find("input[name='clipboard_#{field_name}']")
      .send_keys('')
      .click
      .send_keys([magic_key, 'v'])

    expect(input_field.value).to eq(clipboard_text)

    page.execute_script "$('input[name=\"clipboard_#{field_name}\"]').addClass('is-hidden');"
  end
end
