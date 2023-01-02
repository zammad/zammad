# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MaintenanceRemoveActiveLdapSessions < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    # Only relevant for when ldap integration is used.
    return if !Setting.get('ldap_integration')

    ActiveRecord::SessionStore::Session.destroy_all
  end
end
