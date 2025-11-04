# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Job < ApplicationModel
  include ChecksClientNotification
  include ChecksConditionValidation
  include ChecksHtmlSanitized
  include HasTimeplan
  include HasSearchIndexBackend
  include CanSelector
  include CanSearch
  include TouchesPerformReferences

  include Job::Assets
  include Job::SearchIndex

  OBJECTS_BATCH_SIZE = 2_000

  store     :condition
  store     :perform
  validates :name,    presence: true, uniqueness: { case_sensitive: false }
  validates :object,  presence: true, inclusion: { in: %w[Ticket User Organization] }
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

    Job.where(active: true).each do |job|
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

    object_ids = start_job(start_at, force)

    return if object_ids.nil?

    object_ids.each_slice(10) do |slice|
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
    object_count, _objects = object.constantize.selectors(condition, limit: 1, execution_time: true)
    object_count || 0
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
      next if !start_job_executable?(start_at, force)
      next if !start_job_in_timeplan?(start_at, force)

      object_count, objects = object.constantize.selectors(condition, limit: OBJECTS_BATCH_SIZE, execution_time: true)

      logger.debug { "Job #{name} with #{object_count} object(s)" }

      mark_as_started([object_count, OBJECTS_BATCH_SIZE].min)

      objects&.pluck(:id) || []
    end
  end

  def start_job_executable?(start_at, force)
    return true if executable?(start_at) || force

    if next_run_at && next_run_at <= Time.zone.now
      save!
    end

    false
  end

  def start_job_in_timeplan?(start_at, force)
    return true if in_timeplan?(start_at) || force

    save! # trigger updating matching tickets count and next_run_at time even if not in timeplan

    false
  end

  def mark_as_started(batch_count)
    self.processed = batch_count
    self.running = true
    self.last_run_at = Time.zone.now
    save!
  end

  def run_slice(slice)
    Transaction.execute(disable_notification: disable_notification, reset_user_id: true) do
      _, objects = object.constantize.selectors(condition, limit: OBJECTS_BATCH_SIZE, execution_time: true)

      return if objects.nil?

      objects
        .where(id: slice)
        .each do |object|
          object.perform_changes(self, 'job')
        end
    end
  end
end
