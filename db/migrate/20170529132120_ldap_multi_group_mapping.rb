# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class LdapMultiGroupMapping < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # load existing LDAP config
    ldap_config = Setting.get('ldap_config')

    # exit early if no config is present
    return if ldap_config.blank?
    return if ldap_config['group_role_map'].blank?

    # loop over group role mapping and check
    # if we need to migrate to new array structure
    ldap_config['group_role_map'].each do |source, dest|
      next if dest.is_a?(Array)

      ldap_config['group_role_map'][source] = [dest]
    end

    # store updated
    Setting.set('ldap_config', ldap_config)
  end
end
