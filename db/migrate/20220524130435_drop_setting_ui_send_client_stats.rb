# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class DropSettingUiSendClientStats < ActiveRecord::Migration[6.1]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'ui_send_client_stats')&.destroy
  end
end
