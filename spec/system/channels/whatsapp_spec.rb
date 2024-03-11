# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Manage > Channels > WhatsApp', :use_vcr, required_envs: %w[WHATSAPP_ACCESS_TOKEN WHATSAPP_APP_SECRET WHATSAPP_BUSINESS_ID WHATSAPP_PHONE_NUMBER WHATSAPP_PHONE_NUMBER_ID WHATSAPP_PHONE_NUMBER_NAME], type: :system do
  let(:phone_number_id)   { ENV['WHATSAPP_PHONE_NUMBER_ID'] }
  let(:phone_number)      { ENV['WHATSAPP_PHONE_NUMBER'] }
  let(:phone_number_name) { ENV['WHATSAPP_PHONE_NUMBER_NAME'] }
  let(:business_id)       { ENV['WHATSAPP_BUSINESS_ID'] }
  let(:access_token)      { ENV['WHATSAPP_ACCESS_TOKEN'] }
  let(:app_secret)        { ENV['WHATSAPP_APP_SECRET'] }
  let(:callback_url_uuid) { SecureRandom.uuid }
  let(:verify_token)      { SecureRandom.urlsafe_base64(12) }
  let(:callback_url)      { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}#{Rails.configuration.api_path}/channels_whatsapp_webhook/#{callback_url_uuid}" }

  context 'when adding an account' do
    before do
      allow_any_instance_of(Service::Channel::Whatsapp::Create)
        .to receive(:initial_options)
        .and_return({ adapter: 'whatsapp', callback_url_uuid:, verify_token: })

      visit '#channels/whatsapp'
    end

    it 'creates a new account' do
      click_on 'Add Account'

      in_modal do
        fill_in 'business_id', with: business_id
        fill_in 'access_token', with: access_token
        fill_in 'app_secret', with: app_secret

        click_on 'Next'
      end

      in_modal do
        check_select_field_value('phone_number_id', phone_number_id)

        fill_in 'welcome', with: Faker::Lorem.unique.sentence

        check_switch_field_value('reminder_active', true)

        click_on 'Submit'
      end

      in_modal do
        check_input_field_value('callback_url', callback_url)
        check_copy_to_clipboard_text('callback_url', callback_url)

        check_input_field_value('verify_token', verify_token)
        check_copy_to_clipboard_text('verify_token', verify_token)

        click_on 'Finish'
      end

      expect(page).to have_text(phone_number_name).and have_text(phone_number)
    end
  end

  context 'when editing an account' do
    let(:channel) do
      create(:whatsapp_channel,
             business_id:       business_id,
             access_token:      access_token,
             phone_number_id:   phone_number_id,
             phone_number:      phone_number,
             reminder_active:   false,
             name:              phone_number_name,
             app_secret:        app_secret,
             callback_url_uuid: callback_url_uuid,
             verify_token:      verify_token)
    end

    before do
      channel

      visit '#channels/whatsapp'
    end

    it 'updates an existing account' do
      find('div.btn', text: 'Edit').click

      in_modal do
        expect(page)
          .to have_field('business_id', with: channel.options[:business_id])
          .and have_field('access_token', with: channel.options[:access_token])
          .and have_field('app_secret', with: channel.options[:app_secret])

        click_on 'Next'
      end

      in_modal do
        check_select_field_value('phone_number_id', phone_number_id)

        fill_in 'welcome', with: Faker::Lorem.unique.sentence

        check_switch_field_value('reminder_active', false)

        click_on 'Submit'
      end

      in_modal do
        check_input_field_value('callback_url', callback_url)
        check_copy_to_clipboard_text('callback_url', callback_url)

        check_input_field_value('verify_token', verify_token)
        check_copy_to_clipboard_text('verify_token', verify_token)

        click_on 'Finish'
      end

      expect(page).to have_text(phone_number_name).and have_text(phone_number)
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
