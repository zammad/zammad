class AddUxFlowNextUpToMacros < ActiveRecord::Migration[5.1]
  def change
    add_column :macros, :ux_flow_next_up, :string, default: 'none', null: false
  end
end
