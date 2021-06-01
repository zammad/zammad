# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Scheduler.create_if_not_exists(
  name:   'Process pending tickets',
  method: 'Ticket.process_pending',
  period: 15.minutes,
  prio:   1,
  active: true,
)
Scheduler.create_if_not_exists(
  name:   'Process escalation tickets',
  method: 'Ticket.process_escalation',
  period: 5.minutes,
  prio:   1,
  active: true,
)
Scheduler.create_if_not_exists(
  name:   'Process auto unassign tickets',
  method: 'Ticket.process_auto_unassign',
  period: 10.minutes,
  prio:   1,
  active: true,
)
Scheduler.create_if_not_exists(
  name:          'Import OTRS diff load',
  method:        'Import::OTRS.diff_worker',
  period:        3.minutes,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Check Channels',
  method:        'Channel.fetch',
  period:        30.seconds,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Check streams for Channel',
  method:        'Channel.stream',
  period:        60.seconds,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Generate Session data',
  method:        'Sessions.jobs',
  period:        60.seconds,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Execute jobs',
  method:        'Job.run',
  period:        5.minutes,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Cleanup expired sessions',
  method:        'SessionHelper.cleanup_expired',
  period:        60 * 60 * 12,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Delete old activity stream entries.',
  method:        'ActivityStream.cleanup',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Delete old entries.',
  method:        'RecentView.cleanup',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Delete old online notification entries.',
  method:        'OnlineNotification.cleanup',
  period:        2.hours,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Delete old token entries.',
  method:        'Token.cleanup',
  period:        30.days,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Closed chat sessions where participients are offline.',
  method:        'Chat.cleanup_close',
  period:        15.minutes,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Cleanup closed sessions.',
  method:        'Chat.cleanup',
  period:        5.days,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Cleanup ActiveJob locks.',
  method:        'ActiveJobLockCleanupJob.perform_now',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Cleanup dead sessions.',
  method:        'SessionTimeoutJob.perform_now',
  period:        1.hour,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Sync calendars with ical feeds.',
  method:        'Calendar.sync',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Generate user based stats.',
  method:        'Stats.generate',
  period:        11.minutes,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Delete old stats store entries.',
  method:        'StatsStore.cleanup',
  period:        31.days,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Cleanup HttpLog',
  method:        'HttpLog.cleanup',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Cleanup Cti::Log',
  method:        'Cti::Log.cleanup',
  period:        1.month,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          'Delete obsolete classic IMAP backup.',
  method:        'ImapAuthenticationMigrationCleanupJob.perform_now',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          'Import Jobs',
  method:        'ImportJob.start_registered',
  period:        1.hour,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1
)
Scheduler.create_if_not_exists(
  name:          'Handle data privacy tasks.',
  method:        'DataPrivacyTaskJob.perform_now',
  period:        10.minutes,
  last_run:      Time.zone.now,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
