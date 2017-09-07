class SchedulerStatus < ActiveRecord::Migration[4.2]
  def up
    change_table :schedulers do |t|
      t.string :error_message
      t.string :status
    end
  end
end
