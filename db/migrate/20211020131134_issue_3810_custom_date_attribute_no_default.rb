# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3810CustomDateAttributeNoDefault < ActiveRecord::Migration[6.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    ObjectManager::Attribute
      .where(data_type: %i[date datetime])
      .each { |elem| update_single(elem) }
  end

  def update_single(elem)
    elem.data_option[:diff] = nil
    elem.save!
  rescue => e
    Rails.logger.error e
  end
end
