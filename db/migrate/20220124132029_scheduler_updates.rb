# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class SchedulerUpdates < ActiveRecord::Migration[6.0]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    schedulers_update = [
      {
        name:   'Clean up ActiveJob locks.',
        method: 'ActiveJobLockCleanupJob.perform_now',
      },
      {
        name:   "Clean up 'HttpLog'.",
        method: 'HttpLog.cleanup',
      },
      {
        name:   'Clean up closed sessions.',
        method: 'Chat.cleanup',
      },
      {
        name:   'Clean up dead sessions.',
        method: 'SessionTimeoutJob.perform_now',
      },
      {
        name:   'Clean up expired sessions.',
        method: 'SessionHelper.cleanup_expired',
      },
      {
        name:   'Close chat sessions where participants are offline.',
        method: 'Chat.cleanup_close',
      },
      {
        name:   "Generate 'Session' data.",
        method: 'Sessions.jobs',
      },
      {
        name:   'Generate user-based stats.',
        method: 'Stats.generate',
      },
      {
        name:   'Sync calendars with iCal feeds.',
        method: 'Calendar.sync',
      },
      {
        name:   "Clean up 'Cti::Log.'",
        method: 'Cti::Log.cleanup',
      },
      {
        name:   'Execute import jobs.',
        method: 'ImportJob.start_registered',
      },
      {
        name:   'Process pending tickets.',
        method: 'Ticket.process_pending',
      },
      {
        name:   'Process ticket escalations.',
        method: 'Ticket.process_escalation',
      },
      {
        name:   'Process automatic ticket unassignments.',
        method: 'Ticket.process_auto_unassign',
      },
      {
        name:   'Check channels.',
        method: 'Channel.fetch',
      },
      {
        name:   "Check 'Channel' streams.",
        method: 'Channel.stream',
      },
      {
        name:   'Execute planned jobs.',
        method: 'Job.run',
      },
      {
        name:   "Delete old 'RecentView' entries.",
        method: 'RecentView.cleanup',
      },
    ]

    schedulers_update.each do |scheduler|
      fetched_scheduler = Scheduler.find_by(method: scheduler[:method])
      next if !fetched_scheduler

      if scheduler[:name]
        # p "Updating name of #{scheduler[:name]} to #{scheduler[:name]}"
        fetched_scheduler.name = scheduler[:name]
      end

      fetched_scheduler.save!
    end
  end
end
