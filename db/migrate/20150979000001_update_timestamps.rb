# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UpdateTimestamps < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # get all models
    Models.all.each_value do |value|
      next if !value
      next if !value[:attributes]

      if value[:attributes].include?('updated_at')
        ActiveRecord::Migration.change_column value[:table].to_sym, :updated_at, :datetime, limit: 3, null: false
      end
      if value[:attributes].include?('created_at')
        ActiveRecord::Migration.change_column value[:table].to_sym, :created_at, :datetime, limit: 3, null: false
      end
    end
  end
end
