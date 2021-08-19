# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Job < ApplicationModel
  include ChecksClientNotification
  include ChecksConditionValidation
  include ChecksHtmlSanitized
  include ChecksPerformValidation

  include Job::Assets

  store     :timeplan
  store     :condition
  store     :perform
  validates :name, presence: true

  before_save :updated_matching, :update_next_run_at

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

    tickets = nil
    Transaction.execute(reset_user_id: true) do
      if !executable?(start_at) && force == false
        if next_run_at && next_run_at <= Time.zone.now
          save!
        end
        return
      end

      # find tickets to change
      matching = matching_count
      if self.matching != matching
        self.matching = matching
        save!
      end

      if !in_timeplan?(start_at) && force == false
        if next_run_at && next_run_at <= Time.zone.now
          save!
        end
        return
      end

      ticket_count, tickets = Ticket.selectors(condition, limit: 2_000, execution_time: true)

      logger.debug { "Job #{name} with #{ticket_count} tickets" }

      self.processed = ticket_count || 0
      self.running = true
      self.last_run_at = Time.zone.now
      save!
    end

    tickets&.each do |ticket|
      Transaction.execute(disable_notification: disable_notification, reset_user_id: true) do
        ticket.perform_changes(self, 'job')
      end
    end

    Transaction.execute(reset_user_id: true) do
      self.running = false
      self.last_run_at = Time.zone.now
      save!
    end
  end

  def executable?(start_at = Time.zone.now)
    return false if !active

    # only execute jobs older than 1 min to give admin time to make last-minute changes
    return false if updated_at > Time.zone.now - 1.minute

    # check if job got stuck
    return false if running == true && last_run_at && Time.zone.now - 1.day < last_run_at

    # check if jobs need to be executed
    # ignore if job was running within last 10 min.
    return false if last_run_at && last_run_at > start_at - 10.minutes

    true
  end

  def in_timeplan?(time = Time.zone.now)
    Job::TimeplanCalculation.new(timeplan).contains?(time)
  end

  def matching_count
    ticket_count, _tickets = Ticket.selectors(condition, limit: 1, execution_time: true)
    ticket_count || 0
  end

  def next_run_at_calculate(time = Time.zone.now)
    return nil if !active

    if last_run_at && (time - last_run_at).positive?
      time += 10.minutes
    end

    Job::TimeplanCalculation.new(timeplan).next_at(time)
  end

  private

  def updated_matching
    self.matching = matching_count
  end

  def update_next_run_at
    self.next_run_at = next_run_at_calculate
  end

  def match_minutes(minutes)
    return 0 if minutes < 10

    "#{minutes.to_s.gsub(%r{(\d)\d}, '\\1')}0".to_i
  end

end
