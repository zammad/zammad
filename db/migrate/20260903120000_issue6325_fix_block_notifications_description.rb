# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6325FixBlockNotificationsDescription < ActiveRecord::Migration[8.0]
  PREVIOUS_DESCRIPTION = 'If this regex matches, no notification will be sent by the sender.'.freeze
  NEW_DESCRIPTION      = 'If this regex matches, no notification will be sent to the sender.'.freeze

  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'send_no_auto_response_reg_exp')
    return if setting&.description != PREVIOUS_DESCRIPTION

    setting.update!(description: NEW_DESCRIPTION)
  end
end
