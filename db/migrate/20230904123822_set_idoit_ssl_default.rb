# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SetIdoitSSLDefault < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    config = Setting.get('idoit_config')
    return if config.blank?

    Setting.set('idoit_config', config.merge('verify_ssl' => false))
  end
end
