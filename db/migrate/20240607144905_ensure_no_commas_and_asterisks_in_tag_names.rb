# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class EnsureNoCommasAndAsterisksInTagNames < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Tag::Item
      .where("name LIKE '%,%' OR name LIKE '%*%'")
      .each do |elem|
        elem.name.tr!(',*', ' ')
        elem.save!(validate: false)
      end
  end
end
