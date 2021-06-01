# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# ATTENTION: This migration is most likely not required anymore
# because the encoding error was fixed by using a newer version of the psych gem (3.1.0).
# However, we'll keep it as a regression test.
class Issue2140ResetLdapConfig < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    ldap_config = Setting.get('ldap_config')

    # finish if LDAP config isn't broken
    ldap_config.to_json
  rescue Encoding::UndefinedConversionError
    ldap_config[:wizardData].delete(:backend_user_attributes)

    Setting.set('ldap_config', ldap_config)
  end
end
