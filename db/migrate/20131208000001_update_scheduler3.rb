class UpdateScheduler3 < ActiveRecord::Migration
  def up
    Scheduler.create_or_update(
      :name           => 'Cleanup expired sessions',
      :method         => 'SessionHelper.cleanup_expired',
      :period         => 60 * 60 * 24,
      :prio           => 2,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
  end
  def down
  end
end
