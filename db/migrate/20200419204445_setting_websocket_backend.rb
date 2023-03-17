# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SettingWebsocketBackend < ActiveRecord::Migration[5.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Websocket backend',
      name:        'websocket_backend',
      area:        'System::WebSocket',
      description: 'Defines how to reach websocket server. "websocket" is default on production, "websocketPort" is for CI',
      state:       Rails.env.production? ? 'websocket' : 'websocketPort',
      frontend:    true
    )
  end
end
