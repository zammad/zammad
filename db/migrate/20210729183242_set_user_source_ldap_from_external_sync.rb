# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SetUserSourceLdapFromExternalSync < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    ldap_user_ids = ExternalSync.where(
      source: 'Ldap::User',
      object: 'User'
    ).pluck(:o_id)

    User.where(id: ldap_user_ids).find_each do |user|
      user.update!(source: 'Ldap')
    end
  end
end
