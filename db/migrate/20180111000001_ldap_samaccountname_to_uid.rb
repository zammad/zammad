# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class LdapSamaccountnameToUid < ActiveRecord::Migration[5.1]

  def up
    # return if it's a new setup to avoid running the migration
    return if !Setting.exists?(name: 'system_init_done')

    LdapSource.all.each do |ldap_config|
      migrate_single(ldap_config)
    end
  end

  private

  def migrate_single(ldap_config)
    ldap = ::Ldap.new(ldap_config)

    log(ldap_config, 'Checking for active LDAP configuration...')

    if ldap_config.preferences.blank?
      log(ldap_config, 'Blank LDAP configuration. Exiting.')
      return
    end

    log(ldap_config, 'Checking for different LDAP uid attribute...')
    uid_obsolete = ldap_config.preferences['user_uid']
    uid_new      = uid_attribute_new(ldap_config, ldap)

    if uid_obsolete == uid_new
      log(ldap_config, 'Equal LDAP uid attributes. Exiting.')
      return
    end

    log(ldap_config, 'Starting to migrate LDAP config to new uid attribute...')
    ldap_config.preferences['user_uid'] = uid_new
    ldap_config.save!
    log(ldap_config, 'LDAP uid attribute migration completed.')
  end

  def uid_attribute_new(ldap_config, ldap)
    config = { filter: ldap_config.preferences['user_filter'] }

    ::Ldap::User.new(config, ldap: ldap).uid_attribute
  end

  def log(ldap_config, message)
    Rails.logger.info "LDAP '#{ldap_config.name}' - #{message}"
  end
end
