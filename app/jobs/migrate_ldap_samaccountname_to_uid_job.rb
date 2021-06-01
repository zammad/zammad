# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'ldap'
require_dependency 'ldap/user'

class MigrateLdapSamaccountnameToUidJob < ApplicationJob

  def perform
    Rails.logger.info 'Checking for active LDAP configuration...'

    if ldap_config.blank?
      Rails.logger.info 'Blank LDAP configuration. Exiting.'
      return
    end

    Rails.logger.info 'Checking for different LDAP uid attribute...'
    if uid_attribute_obsolete == uid_attribute_new
      Rails.logger.info 'Equal LDAP uid attributes. Exiting.'
      return
    end

    Rails.logger.info 'Starting to migrate LDAP config to new uid attribute...'
    migrate_ldap_config
    Rails.logger.info 'LDAP uid attribute migration completed.'
  end

  private

  def ldap
    @ldap ||= ::Ldap.new(ldap_config)
  end

  def ldap_config
    @ldap_config ||= Import::Ldap.config
  end

  def uid_attribute_new
    @uid_attribute_new ||= begin
      config = {
        filter: ldap_config['user_filter']
      }

      ::Ldap::User.new(config, ldap: ldap).uid_attribute
    end
  end

  def uid_attribute_obsolete
    @uid_attribute_obsolete ||= ldap_config['user_uid']
  end

  def migrate_ldap_config
    ldap_config_new = ldap_config.merge(
      'user_uid' => uid_attribute_new
    )

    Setting.set('ldap_config', ldap_config_new)
  end
end
