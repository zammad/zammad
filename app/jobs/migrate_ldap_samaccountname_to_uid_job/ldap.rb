# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MigrateLdapSamaccountnameToUidJob::Ldap
  attr_accessor :ldap, :ldap_config

  def initialize(ldap_config)
    @ldap_config = ldap_config
    @ldap        = ::Ldap.new(ldap_config)
  end

  def perform
    log('Checking for active LDAP configuration...')

    if ldap_config.preferences.blank?
      log('Blank LDAP configuration. Exiting.')
      return
    end

    log('Checking for different LDAP uid attribute...')
    if uid_attribute_obsolete == uid_attribute_new
      log('Equal LDAP uid attributes. Exiting.')
      return
    end

    log('Starting to migrate LDAP config to new uid attribute...')
    migrate_ldap_config
    log('LDAP uid attribute migration completed.')
  end

  def uid_attribute_new
    @uid_attribute_new ||= begin
      config = {
        filter: ldap_config.preferences['user_filter']
      }

      ::Ldap::User.new(config, ldap: ldap).uid_attribute
    end
  end

  def uid_attribute_obsolete
    @uid_attribute_obsolete ||= ldap_config.preferences['user_uid']
  end

  def migrate_ldap_config
    ldap_config_new = ldap_config.preferences.merge(
      'user_uid' => uid_attribute_new
    )

    ldap_config.update(preferences: ldap_config_new)
  end

  def log(message)
    Rails.logger.info "LDAP '#{ldap_config.name}' - #{message}"
  end
end
