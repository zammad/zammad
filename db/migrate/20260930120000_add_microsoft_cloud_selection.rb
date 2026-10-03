# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddMicrosoftCloudSelection < ActiveRecord::Migration[8.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_microsoft_office365_credentials')
    return if !setting || !setting.options[:form]

    form = setting.options[:form]
    if form.none? { |field| field[:name] == 'cloud' }
      tenant_index = form.index { |field| field[:name] == 'app_tenant' }
      form.insert(tenant_index ? tenant_index + 1 : form.length, cloud_field)
    end

    validations = (Array(setting.preferences[:validations]) + ['Setting::Validation::MicrosoftOffice365Credentials']).uniq
    setting.assign_attributes(options: setting.options.merge(form:), preferences: setting.preferences.merge(validations:))
    # Preserve existing credentials; the validator governs subsequent edits.
    setting.save!(validate: false)
  end

  private

  def cloud_field
    {
      display:   'Microsoft cloud',
      null:      true,
      default:   'global',
      name:      'cloud',
      tag:       'select',
      options:   {
        'global' => 'Global cloud',
        'us_gov' => 'US Government (GCC High)',
      },
      translate: true,
    }
  end
end
