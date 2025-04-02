# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SettingAddAutoRestartOptout < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Auto Shutdown',
      name:        'auto_shutdown',
      area:        'Core::WebApp',
      description: 'Enable or disable self-shutdown of Zammad processes after significant configuration changes. This should only be used if the controlling process manager like systemd or docker supports an automatic restart policy.',
      options:     {},
      state:       true,
      preferences: { online_service_disable: true },
      frontend:    false
    )
  end
end
