# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UpdateMicrosoftOffice365RequireVerifiedEmailDomainHelp, type: :db_migration do
  let(:setting)       { Setting.find_by(name: 'auth_microsoft_office365_credentials') }
  let(:previous_help) { 'Requires the "xms_edov" ID token claim (along with the "email" claim) to be present and true before trusting an incoming email address for account auto-linking.' }

  def store_form(form)
    setting.update!(options: setting.options.merge(form:))
  end

  def stored_field
    Setting
      .find_by(name: 'auth_microsoft_office365_credentials')
      .options[:form]
      .find { |field| field[:name] == 'require_verified_email_domain' }
  end

  context 'when the field carries the previous help text' do
    before do
      form  = setting.options[:form]
      field = form.find { |f| f[:name] == 'require_verified_email_domain' }

      if field.nil?
        field = { 'name' => 'require_verified_email_domain', 'display' => 'Require verified email domain', 'tag' => 'boolean' }
        form.push(field)
      end

      field['help'] = previous_help

      store_form(form)
    end

    it 'updates the help text to also require a matching "email" claim' do
      expect { migrate }
        .to change { stored_field[:help] }
        .from(previous_help)
        .to(include('the "email" claim to match the incoming email address'))
    end
  end

  context 'when the field is not present' do
    before do
      store_form(setting.options[:form].reject { |field| field[:name] == 'require_verified_email_domain' })
    end

    it 'does not change the setting' do
      expect { migrate }.not_to change { Setting.find_by(name: 'auth_microsoft_office365_credentials').options }
    end
  end
end
