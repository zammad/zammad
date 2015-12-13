class UpdateChat4 < ActiveRecord::Migration
  def up
    Scheduler.create_or_update(
      name: 'Closed chat sessions where participients are offline.',
      method: 'Chat.cleanup_close',
      period: 60 * 15,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Scheduler.create_or_update(
      name: 'Cleanup closed sessions.',
      method: 'Chat.cleanup',
      period: 5.days,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end

  def down
  end
end
