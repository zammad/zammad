# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6603AuthThirdPartyNoCreateUserWording < ActiveRecord::Migration[8.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'auth_third_party_no_create_user')&.update!(
      title:       'Skip user creation on logon',
      description: 'Skips creating users when they sign in via a third-party application.',
    )
  end
end
