class UpdateScheduler2 < ActiveRecord::Migration
  def up
    Scheduler.create_or_update(
      :name           => 'Generate Session data',
      :method         => 'Sessions.jobs',
      :period         => 60,
      :prio           => 1,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
  end
  def down
  end
end
