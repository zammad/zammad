class UpdateCleanup < ActiveRecord::Migration
  def up

    # delete old entries
    Scheduler.create_or_update(
      name: 'Delete old online notification entries.',
      method: 'OnlineNotification.cleanup',
      period: 2.hours,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    add_index :online_notifications, [:seen]
    add_index :online_notifications, [:created_at]
    add_index :online_notifications, [:updated_at]

    Scheduler.create_or_update(
      name: 'Delete old token entries.',
      method: 'Token.cleanup',
      period: 30.days,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    add_index :tokens, :persistent
  end
end
