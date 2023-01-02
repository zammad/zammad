# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class AndOrConditionsSettingDefault < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    expert_setting = Setting.find_by(name: 'ticket_allow_expert_conditions')
    return if !expert_setting

    expert_setting.area = 'Ticket::Core'
    expert_setting.state_current = { value: true }
    expert_setting.state_initial = { value: true }
    expert_setting.preferences[:online_service_disable] = true
    expert_setting.preferences.delete(:prio)

    expert_setting.save!
  end
end
