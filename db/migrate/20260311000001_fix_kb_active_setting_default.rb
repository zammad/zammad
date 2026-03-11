# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FixKbActiveSettingDefault < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'kb_active')&.tap do |setting|
      setting.state_initial = { value: false }
      setting.state_current = { value: KnowledgeBase.active.exists? }
      setting.save!
    end
  end
end
