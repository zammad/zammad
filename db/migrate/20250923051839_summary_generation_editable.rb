# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class SummaryGenerationEditable < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    attribute = ObjectManager::Attribute.get(
      object: 'Group',
      name:   'summary_generation',
    )
    return if !attribute

    attribute.update!(editable: false)
  end
end
