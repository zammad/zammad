class UpdateSla < ActiveRecord::Migration
  def up
    Scheduler.create(
      :name           => 'Check Channels',
      :method         => 'Channel.fetch',
      :period         => 30,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
    Scheduler.create(
      :name           => 'Import OTRS diff load',
      :method         => 'Import::OTRS.diff_loop',
      :period         => 60 * 10,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
    Scheduler.create(
      :name           => 'Generate Session data',
      :method         => 'Session.jobs',
      :period         => 60,
      :active         => true,
      :updated_by_id  => 1,
      :created_by_id  => 1,
    )
    add_column :slas, :first_response_time, :integer, :null => true
    add_column :slas, :update_time,         :integer, :null => true
    add_column :slas, :close_time,          :integer, :null => true
  end

  def down
  end
end
