# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Webhook', type: :system do
  context 'when ajax pagination' do
    include_examples 'pagination', model: :webhook, klass: Webhook, path: 'manage/webhook'
  end

  context 'when showing the example payload' do
    it 'shows correctly' do
      visit '/#manage/webhook'

      within :active_content do
        click 'a[data-type="payload"]'
      end

      in_modal do
        expect(page).to have_text('X-Zammad-Trigger:')
      end
    end
  end

  context 'when creating new webhook' do
    let(:custom_payload) { JSON.pretty_generate(Webhook::PreDefined::Mattermost.new.custom_payload) }

    before do
      visit '/#manage/webhook'

      within :active_content do
        click 'button[data-toggle="dropdown"]'
        click '.dropdown-menu [role="menuitem"]', text: 'Pre-defined Webhook'
      end
    end

    it 'provides pre-defined webhooks' do
      in_modal do
        find('[name="pre_defined_webhook_id"]').select 'Mattermost Notifications'

        click_on 'Next'

        expect(page).to have_field('Name', with: 'Mattermost Notifications')
        expect(page).to have_select('Pre-defined Webhook', text: 'Mattermost Notifications', disabled: :all)
        expect(page).to have_field('Messaging Username', with: '')
        expect(page).to have_field('Messaging Channel', with: '')
        expect(page).to have_field('Messaging Icon URL', with: 'https://zammad.com/assets/images/logo-200x200.png')
        expect(page).to have_field('Custom Payload', checked: false, visible: :all)
        expect(page).to have_field('custom_payload', with: custom_payload, disabled: :all, visible: :all)
        expect(page).to have_field('Note', with: 'Pre-defined webhook for Mattermost Notifications.')

        fill_in 'Endpoint', with: 'https://example.com/mattermost_endpoint'
        fill_in 'Messaging Username', with: 'username'
        fill_in 'Messaging Channel', with: '#channel'

        click_on 'Submit'
      end

      expect(Webhook.last).to have_attributes(
        name:                     'Mattermost Notifications',
        pre_defined_webhook_type: 'Mattermost',
        customized_payload:       false,
        custom_payload:           nil,
        note:                     'Pre-defined webhook for Mattermost Notifications.',
        preferences:              include(
          pre_defined_webhook: include(
            messaging_username: 'username',
            messaging_channel:  '#channel',
            messaging_icon_url: 'https://zammad.com/assets/images/logo-200x200.png',
          ),
        ),
      )
    end

    context 'with customized payload' do
      let(:custom_payload) { JSON.pretty_generate(Webhook::PreDefined::RocketChat.new.custom_payload) }

      it 'overrides pre-defined payload' do
        in_modal do
          find('[name="pre_defined_webhook_id"]').select 'Rocket Chat Notifications'

          click_on 'Next'

          expect(page).to have_field('Custom Payload', checked: false, visible: :all)
          expect(page).to have_field('custom_payload', with: custom_payload, disabled: :all, visible: :all)

          fill_in 'Endpoint', with: 'https://example.com/rocketchat_endpoint'
          click 'label[for="attribute-customized_payload"]'

          click_on 'Submit'
        end

        expect(Webhook.last).to have_attributes(
          pre_defined_webhook_type: 'RocketChat',
          customized_payload:       true,
          custom_payload:           custom_payload.gsub(%r{\n}, "\r\n"),
        )
      end
    end
  end

  context 'when editing existing webhook' do
    let!(:webhook)       { create(:mattermost_webhook) }
    let(:custom_payload) { JSON.pretty_generate(Webhook::PreDefined::Mattermost.new.custom_payload) }

    before do
      visit '/#manage/webhook'

      within :active_content do
        click "tr[data-id='#{webhook.id}'] td:first-child"
      end
    end

    it 'supports pre-defined webhooks' do
      in_modal do
        expect(page).to have_select('Pre-defined Webhook', text: 'Mattermost Notifications', disabled: :all)
        expect(page).to have_field('Messaging Username', with: webhook.preferences['pre_defined_webhook']['messaging_username'])
        expect(page).to have_field('Messaging Channel', with: webhook.preferences['pre_defined_webhook']['messaging_channel'])
        expect(page).to have_field('Messaging Icon URL', with: webhook.preferences['pre_defined_webhook']['messaging_icon_url'])
        expect(page).to have_field('Custom Payload', checked: false, visible: :all)
        expect(page).to have_field('custom_payload', with: custom_payload, disabled: :all, visible: :all)

        fill_in 'Messaging Username', with: 'username'
        fill_in 'Messaging Channel', with: '#channel'
        fill_in 'Messaging Icon URL', with: 'https://example.com/logo.png'

        click_on 'Submit'
      end

      expect(webhook.reload).to have_attributes(
        preferences: include(
          pre_defined_webhook: include(
            messaging_username: 'username',
            messaging_channel:  '#channel',
            messaging_icon_url: 'https://example.com/logo.png',
          ),
        ),
      )
    end

    context 'with customized payload' do
      let!(:webhook) { create(:rocketchat_webhook, customized_payload: true, custom_payload: '{}') }

      it 'resets custom payload' do
        in_modal do
          expect(page).to have_field('Custom Payload', checked: true, visible: :all)
          expect(page).to have_field('custom_payload', with: webhook.custom_payload, disabled: :all, visible: :all)

          click 'label[for="attribute-customized_payload"]'

          click_on 'Submit'
        end

        expect(webhook.reload).to have_attributes(
          customized_payload: false,
          custom_payload:     nil,
        )
      end
    end
  end

  context 'when cloning an existing webhook' do
    let!(:webhook)       { create(:mattermost_webhook) }
    let(:custom_payload) { JSON.pretty_generate(Webhook::PreDefined::Mattermost.new.custom_payload) }

    before do
      visit '/#manage/webhook'

      within :active_content do
        row = find("tr[data-id='#{webhook.id}']")
        row.find('.js-action').click
        row.find('.js-clone').click
      end
    end

    it 'supports pre-defined webhooks (#5524)' do
      in_modal do
        expect(page).to have_field('Name', with: 'Clone: Mattermost Notifications')
        expect(page).to have_select('Pre-defined Webhook', text: 'Mattermost Notifications', disabled: :all)
        expect(page).to have_field('Messaging Username', with: webhook.preferences['pre_defined_webhook']['messaging_username'])
        expect(page).to have_field('Messaging Channel', with: webhook.preferences['pre_defined_webhook']['messaging_channel'])
        expect(page).to have_field('Messaging Icon URL', with: webhook.preferences['pre_defined_webhook']['messaging_icon_url'])
        expect(page).to have_field('Custom Payload', checked: false, visible: :all)
        expect(page).to have_field('custom_payload', with: custom_payload, disabled: :all, visible: :all)
        expect(page).to have_field('Note', with: 'Pre-defined webhook for Mattermost Notifications.')

        fill_in 'Endpoint', with: 'https://example.com/mattermost_endpoint'
        fill_in 'Messaging Username', with: 'username'
        fill_in 'Messaging Channel', with: '#channel'
        fill_in 'Messaging Icon URL', with: 'https://example.com/logo.png'

        click_on 'Submit'
      end

      expect(Webhook.last).to have_attributes(
        name:                     'Clone: Mattermost Notifications',
        pre_defined_webhook_type: 'Mattermost',
        customized_payload:       false,
        custom_payload:           nil,
        note:                     'Pre-defined webhook for Mattermost Notifications.',
        preferences:              include(
          pre_defined_webhook: include(
            messaging_username: 'username',
            messaging_channel:  '#channel',
            messaging_icon_url: 'https://example.com/logo.png',
          ),
        ),
      )
    end
  end

  context 'when checking custom payload validation' do
    it 'shows error message' do
      visit '/#manage/webhook'

      within :active_content do
        click 'button[data-type="new"]'
      end

      in_modal do
        fill_in 'name', with: 'Test'
        fill_in 'endpoint', with: 'https://example.com/webhook'

        click 'label[for="attribute-customized_payload"]'

        find(:code_editor, 'custom_payload').send_keys 'invalid json'

        expect(page).to have_css('div.CodeMirror-lint-marker-error')

        click '.js-submit'

        expect(page).to have_css('div[data-attribute-name="custom_payload"].has-error')
          .and have_text('Please enter a valid JSON string.')
      end
    end
  end

  context 'when deleting' do
    let!(:webhook) { create(:webhook) }
    let!(:trigger) { create(:trigger, perform: { 'notification.webhook' => { 'webhook_id' => webhook.id.to_s } }) }

    it 'referenced webhook shows error message' do
      visit '/#manage/webhook'

      within :active_content do
        click '.js-action'
        click '.js-delete'
      end

      in_modal do
        click '.js-submit'

        expect(page).to have_text('Cannot delete').and(have_text("##{trigger.id}"))
      end
    end
  end
end
