# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class LdapSourceConfig < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    LdapSource.in_batches.each_record do |source|
      source.update!(preferences: adjust_config(source.preferences))
    end
  end

  private

  LDAP_SSL_MAPPING = {
    'ldap'  => 'off',
    'ldaps' => 'ssl',
  }.freeze

  def adjust_config(preferences)
    ssl_legacy(preferences)

    change_host_and_ssl(preferences, 'ldap')
    change_host_and_ssl(preferences, 'ldaps')

    preferences.delete('host_url')
    preferences
  end

  def ssl_legacy(preferences)
    return preferences if preferences.key?('host_url')
    return preferences if !preferences.key?('ssl')

    preferences['ssl'] = 'ssl' if preferences['ssl']
    preferences['ssl'] = 'off' if !preferences['ssl']
  end

  def change_host_and_ssl(preferences, protocol)
    return preferences if !preferences.key?('host_url')
    return preferences if !preferences['host_url'].starts_with?("#{protocol}://")

    preferences['host'] = preferences['host_url'].sub("#{protocol}://", '')
    preferences['ssl']  = LDAP_SSL_MAPPING[protocol]
  end
end
