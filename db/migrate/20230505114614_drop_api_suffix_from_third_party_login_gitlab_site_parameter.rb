# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class DropApiSuffixFromThirdPartyLoginGitLabSiteParameter < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'auth_gitlab_credentials')
    return if !setting

    site_field_index = setting.options['form'].index { |field| field['name'] == 'site' }
    setting.options['form'][site_field_index]['placeholder'] = 'https://gitlab.YOURDOMAIN.com/'

    remove_api_suffix_from_current_value(setting)

    setting.save!
  end

  private

  def remove_api_suffix_from_current_value(setting)
    current_value = setting.state_current['value']
    return if current_value.blank?

    current_value['site'].sub!('api/v4', '')
  end
end
