# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Job < ApplicationModel
  include ChecksClientNotification
  include ChecksConditionValidation
  include ChecksHtmlSanitized
  include HasTimeplan

  include Job::Assets

  store     :condition
  store     :perform
  validates :name,    presence: true
  validates :perform, 'validations/verify_perform_rules': true

  before_save :updated_matching, :update_next_run_at

  validates :note, length: { maximum: 250 }
  sanitized_html :note

=begin

verify each job if needed to run (e. g. if true and times are matching) and execute it

Job.run

=end

  def self.run
    start_at = Time.zone.now
    jobs = Job.where(active: true)
    jobs.each do |job|
      next if !job.executable?

      job.run(false, start_at)
    end
    true
  end

=begin

execute a single job if needed (e. g. if true and times are matching)

job = Job.find(123)

job.run

force to run job (ignore times are matching)

job.run(true)

=end

  def run(force = false, start_at = Time.zone.now)
    logger.debug { "Execute job #{inspect}" }

    ticket_ids = start_job(start_at, force)

    return if ticket_ids.nil?

    ticket_ids&.each_slice(10) do |slice|
      run_slice(slice)
    end

    finish_job
  end

  def executable?(start_at = Time.zone.now)
    return false if !active

    # only execute jobs older than 1 min to give admin time to make last-minute changes
    return false if updated_at > 1.minute.ago

    # check if job got stuck
    return false if running == true && last_run_at && 1.day.ago < last_run_at

    # check if jobs need to be executed
    # ignore if job was running within last 10 min.
    return false if last_run_at && last_run_at > start_at - 10.minutes

    true
  end

  def matching_count
    ticket_count, _tickets = Ticket.selectors(condition, limit: 1, execution_time: true)
    ticket_count || 0
  end

  private

  def next_run_at_calculate(time = Time.zone.now)
    return nil if !active

    if last_run_at && (time - last_run_at).positive?
      time += 10.minutes
    end

    timeplan_calculation.next_at(time)
  end

  def updated_matching
    self.matching = matching_count
  end

  def update_next_run_at
    self.next_run_at = next_run_at_calculate
  end

  def finish_job
    Transaction.execute(reset_user_id: true) do
      mark_as_finished
    end
  end

  def mark_as_finished
    self.running = false
    self.last_run_at = Time.zone.now
    save!
  end

  def start_job(start_at, force)
    Transaction.execute(reset_user_id: true) do
      if start_job_executable?(start_at, force) && start_job_ensure_matching_count && start_job_in_timeplan?(start_at, force)
        ticket_count, tickets = Ticket.selectors(condition, limit: 2_000, execution_time: true)

        logger.debug { "Job #{name} with #{ticket_count} tickets" }

        mark_as_started(ticket_count)

        tickets&.pluck(:id) || []
      end
    end
  end

  def start_job_executable?(start_at, force)
    return true if executable?(start_at) || force

    if next_run_at && next_run_at <= Time.zone.now
      save!
    end

    false
  end

  def start_job_ensure_matching_count
    matching = matching_count

    if self.matching != matching
      self.matching = matching
      save!
    end

    true
  end

  def start_job_in_timeplan?(start_at, force)
    return true if in_timeplan?(start_at) || force

    if next_run_at && next_run_at <= Time.zone.now
      save!
    end

    false
  end

  def mark_as_started(ticket_count)
    self.processed = ticket_count || 0
    self.running = true
    self.last_run_at = Time.zone.now
    save!
  end

  def run_slice(slice)
    Transaction.execute(disable_notification: disable_notification, reset_user_id: true) do
      _, tickets = Ticket.selectors(condition, limit: 2_000, execution_time: true)

      tickets
        &.where(id: slice)
        &.each do |ticket|
          ticket.perform_changes(self, 'job')
        end
    end
  end
end
