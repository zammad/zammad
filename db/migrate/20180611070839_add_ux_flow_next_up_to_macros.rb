# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AddUxFlowNextUpToMacros < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :macros, :ux_flow_next_up, :string, default: 'none', null: false

    Macro.connection.schema_cache.clear!
    Macro.reset_column_information

    macro = Macro.find_by(name: 'Close & Tag as Spam')
    return if !macro

    macro.ux_flow_next_up = 'next_task'
    macro.save!
  end
end
