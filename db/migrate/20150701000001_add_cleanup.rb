class AddCleanup < ActiveRecord::Migration
  def up

    # delete old entries
    Scheduler.create_or_update(
      name: 'Delete old activity stream entries.',
      method: 'ActivityStream.cleanup',
      period: 1.day,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Scheduler.create_or_update(
      name: 'Delete old online notification entries.',
      method: 'OnlineNotification.cleanup',
      period: 1.day,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
    Scheduler.create_or_update(
      name: 'Delete old entries.',
      method: 'RecentView.cleanup',
      period: 1.day,
      prio: 2,
      active: true,
      updated_by_id: 1,
      created_by_id: 1,
    )
  end
end
