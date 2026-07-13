# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddRequireVerifiedEmailDomainToMicrosoftOffice365Credentials < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_microsoft_office365_credentials')
    return if !setting

    form = setting.options[:form]
    return if !form
    return if form.any? { |field| field[:name] == 'require_verified_email_domain' }

    callback_url_index = form.index { |field| field[:name] == 'callback_url' }
    new_field          = {
      display:   'Require verified email domain',
      null:      true,
      default:   false,
      name:      'require_verified_email_domain',
      tag:       'boolean',
      options:   {
        true  => 'yes',
        false => 'no',
      },
      translate: true,
      help:      'Requires the "xms_edov" ID token claim (along with the "email" claim) to be present and true before trusting an incoming email address for account auto-linking. Both must first be configured as optional claims on the Azure app registration. Until that is done, enabling this blocks all Microsoft 365 account auto-linking by email.',
    }

    form.insert(callback_url_index || form.length, new_field)

    setting.update!(options: setting.options.merge(form:))
  end
end
