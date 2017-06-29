class AddChannelListenScheduler < ActiveRecord::Migration
  def up
    Scheduler.create_or_update(
      name:          'Check listeners for Channel',
      method:        'Channel.listen',
      period:        60,
      prio:          1,
      active:        true,
      updated_by_id: 1,
      created_by_id: 1
    )
  end
end
