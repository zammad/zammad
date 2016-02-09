class UpdtateTimeSlaTime < ActiveRecord::Migration
  def up
    return if !Ticket.column_names.include?('updtate_time_sla_time')
    rename_column :tickets, :updtate_time_sla_time, :update_time_sla_time
  end
end
