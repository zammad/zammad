# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SlackGroupConfigIssue587 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'slack_config')
    return if !setting

    return if !setting.state_current['value']
    return if !setting.state_current['value']['items']

    config_item = setting.state_current['value']['items'].first
    return if !config_item

    return if !config_item.key?('group_id')

    config_item['group_ids'] = config_item.delete('group_id')

    setting.save!
  end
end
