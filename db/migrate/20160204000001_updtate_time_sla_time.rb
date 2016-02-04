class UpdtateTimeSlaTime < ActiveRecord::Migration
  def up
    rename_column :tickets, :updtate_time_sla_time, :update_time_sla_time
  end
end
