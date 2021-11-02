# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SlaAddResponseTime < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    change_table :slas do |t|
      t.integer :response_time
    end

    Sla.reset_column_information
  end
end
