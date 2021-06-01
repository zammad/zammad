# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SettingAddSenderFormatAgentName < ActiveRecord::Migration[5.1]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'ticket_define_email_from')
    return if !setting

    setting.options[:form][0][:options][:AgentName] = 'Agent Name'
    setting.save!
  end
end
