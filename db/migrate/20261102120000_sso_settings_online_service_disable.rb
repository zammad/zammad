# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class SsoSettingsOnlineServiceDisable < ActiveRecord::Migration[8.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    %w[auth_sso auth_sso_trusted_ips].each do |name|
      setting = Setting.find_by(name: name)
      next if !setting

      setting.preferences[:online_service_disable] = true
      setting.save!
    end
  end
end
