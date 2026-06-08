# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ObjectManagerAttributesNoBlankDisplayLabel < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_existing_attributes
  end

  private

  def update_existing_attributes
    ObjectManager::Attribute.where(display: '').find_each { |a| a.update!(display: a.name) }
  end
end
