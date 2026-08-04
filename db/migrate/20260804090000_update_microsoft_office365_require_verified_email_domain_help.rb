# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class UpdateMicrosoftOffice365RequireVerifiedEmailDomainHelp < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_microsoft_office365_credentials')
    return if !setting

    form = setting.options[:form]
    return if !form

    field = form.find { |f| f[:name] == 'require_verified_email_domain' }
    return if !field

    field[:help] = 'Requires the "xms_edov" ID token claim to be true, and the "email" claim to match the incoming email address, before trusting that address for account auto-linking. Both claims must first be configured as optional claims on the Azure app registration. Until that is done, enabling this blocks all Microsoft 365 account auto-linking by email.'

    setting.update!(options: setting.options.merge(form:))
  end
end
