require 'scheduler'
require 'setting'
class SchedulerUpdate < ActiveRecord::Migration
  def up
    add_column :schedulers, :prio,     :integer,  :null => true
    Scheduler.reset_column_information
    Scheduler.create_or_update(
      :name           => 'Import OTRS diff load',
      :method         => 'Import::OTRS2.diff_worker',
      :period         => 60 * 3,
      :prio           => 1,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
    Scheduler.create_or_update(
      :name           => 'Check Channels',
      :method         => 'Channel.fetch',
      :period         => 30,
      :prio           => 1,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
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
    remove_column :schedulers, :prio
  end
end
