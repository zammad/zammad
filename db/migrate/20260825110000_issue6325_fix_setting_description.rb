# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6325FixSettingDescription < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'send_no_auto_response_reg_exp')&.update(description: 'If this regex matches, no notification will be sent to the sender.')

    Translation.sync
  end
end
