class SchedulerStatus < ActiveRecord::Migration
  def up
    change_table :schedulers do |t|
      t.string :error_message
      t.string :status
    end
  end
end
