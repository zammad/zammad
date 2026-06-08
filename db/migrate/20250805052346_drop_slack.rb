# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class DropSlack < ActiveRecord::Migration[7.2]
  DROP_SETTINGS = %w[slack_integration slack_config 6000_slack_webhook].freeze

  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # drop slack settings
    Setting.where(name: DROP_SETTINGS).destroy_all
  end
end
