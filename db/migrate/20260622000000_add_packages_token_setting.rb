# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddPackagesTokenSetting < ActiveRecord::Migration[7.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Packages Token',
      name:        'packages_token',
      area:        'Core',
      description: 'This setting defines the token to access the support.zammad.com instance for package remote commands.',
      options:     {},
      state:       '',
      preferences: { online_service_disable: true, permission: ['admin.package'] },
      frontend:    false
    )
  end

end
