class AddUxFlowNextUpToMacros < ActiveRecord::Migration[5.1]
  def change

    # return if it's a new setup
    return if !Setting.find_by(name: 'system_init_done')

    add_column :macros, :ux_flow_next_up, :string, default: 'none', null: false

    Macro.connection.schema_cache.clear!
    Macro.reset_column_information

    macro = Macro.find_by(name: 'Close & Tag as Spam')
    return if !macro
    macro.ux_flow_next_up = 'next_task'
    macro.save!
  end
end
