# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6158AISummaryDisabledOption < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    attribute = ObjectManager::Attribute.get(
      object: 'Group',
      name:   'summary_generation',
    )
    return if !attribute

    options = attribute.data_option['options'] || []
    return if options.any? { |option| option['value'] == 'disabled' }

    options << { 'name' => 'Hide ticket summary sidebar', 'value' => 'disabled' }
    attribute.data_option['options'] = options
    attribute.save!
  end
end
