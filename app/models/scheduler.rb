# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Scheduler < ApplicationModel
  include ChecksHtmlSanitized
  include HasTimeplan

  validates :note, length: { maximum: 250 }
  sanitized_html :note

  scope :failed_jobs, -> { where(status: 'error', active: false) }

  # Jobs running more often than every 5 minutes are kept in a continuous thread.
  #
  # @example
  #   Scheduler.runs_as_persistent_loop?
  #
  # return [true]
  def runs_as_persistent_loop?
    active && period && period <= 5.minutes
  end

  # This function restarts failed jobs to retry them
  #
  # @example
  #   Scheduler.restart_failed_jobs
  #
  # return [true]
  def self.restart_failed_jobs
    failed_jobs.each do |job|
      job.update!(active: true)
    end

    true
  end
end
