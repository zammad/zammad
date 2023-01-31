# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

Scheduler.create_if_not_exists(
  name:   __('Process pending tickets.'),
  method: 'Ticket.process_pending',
  period: 15.minutes,
  prio:   1,
  active: true,
)
Scheduler.create_if_not_exists(
  name:   __('Process ticket escalations.'),
  method: 'Ticket.process_escalation',
  period: 5.minutes,
  prio:   1,
  active: true,
)
Scheduler.create_if_not_exists(
  name:   __('Process automatic ticket unassignments.'),
  method: 'Ticket.process_auto_unassign',
  period: 10.minutes,
  prio:   1,
  active: true,
)
Scheduler.create_if_not_exists(
  name:          __('Check channels.'),
  method:        'Channel.fetch',
  period:        30.seconds,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __("Check 'Channel' streams."),
  method:        'Channel.stream',
  period:        60.seconds,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __("Generate 'Session' data."),
  method:        'Sessions.jobs',
  period:        60.seconds,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __('Execute planned jobs.'),
  method:        'Job.run',
  period:        5.minutes,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __('Clean up expired sessions.'),
  method:        'SessionHelper.cleanup_expired',
  period:        60 * 60 * 12,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __('Delete old activity stream entries.'),
  method:        'ActivityStream.cleanup',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __("Delete old 'RecentView' entries."),
  method:        'RecentView.cleanup',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Delete old online notification entries.'),
  method:        'OnlineNotification.cleanup',
  period:        2.hours,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Delete old token entries.'),
  method:        'Token.cleanup',
  period:        30.days,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Close chat sessions where participants are offline.'),
  method:        'Chat.cleanup_close',
  period:        15.minutes,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Clean up closed sessions.'),
  method:        'Chat.cleanup',
  period:        5.days,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Clean up ActiveJob locks.'),
  method:        'ActiveJobLockCleanupJob.perform_now',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Clean up dead sessions.'),
  method:        'SessionTimeoutJob.perform_now',
  period:        1.hour,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Sync calendars with iCal feeds.'),
  method:        'Calendar.sync',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Generate user-based stats.'),
  method:        'Stats.generate',
  period:        11.minutes,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Delete old stats store entries.'),
  method:        'StatsStore.cleanup',
  period:        31.days,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __("Clean up 'HttpLog'."),
  method:        'HttpLog.cleanup',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __("Clean up 'Cti::Log'."),
  method:        'Cti::Log.cleanup',
  period:        1.month,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __("Clean up 'DataPrivacyTask'."),
  method:        'DataPrivacyTask.cleanup',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_or_update(
  name:          __('Delete obsolete classic IMAP backup.'),
  method:        'ImapAuthenticationMigrationCleanupJob.perform_now',
  period:        1.day,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __('Execute import jobs.'),
  method:        'ImportJob.start_registered',
  period:        1.hour,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1
)
Scheduler.create_if_not_exists(
  name:          __('Handle data privacy tasks.'),
  method:        'DataPrivacyTaskJob.perform_now',
  period:        10.minutes,
  last_run:      Time.zone.now,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __('Delete old upload cache entries.'),
  method:        'UploadCacheCleanupJob.perform_now',
  period:        1.month,
  prio:          2,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __('Clean up cache.'),
  method:        'CacheClearJob.perform_now',
  period:        10.minutes,
  prio:          2,
  active:        true,
  timeplan:      {
    'days'    => {
      'Mon' => true,
      'Tue' => true,
      'Wed' => true,
      'Thu' => true,
      'Fri' => true,
      'Sat' => true,
      'Sun' => true
    },
    'hours'   => {
      '23' => true
    },
    'minutes' => {
      '0' => true
    }
  },
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __('Update exchange oauth 2 token.'),
  method:        'ExternalCredential::Exchange.refresh_token',
  period:        10.minutes,
  prio:          1,
  active:        true,
  updated_by_id: 1,
  created_by_id: 1,
)
Scheduler.create_if_not_exists(
  name:          __('Clean up mobile taskbars.'),
  method:        'TaskbarCleanupJob.perform_now',
  period:        10.minutes,
  prio:          2,
  active:        true,
  timeplan:      {
    'days'    => {
      'Mon' => true,
      'Tue' => true,
      'Wed' => true,
      'Thu' => true,
      'Fri' => true,
      'Sat' => true,
      'Sun' => true
    },
    'hours'   => {
      '1' => true
    },
    'minutes' => {
      '0' => true
    }
  },
  updated_by_id: 1,
  created_by_id: 1,
)
