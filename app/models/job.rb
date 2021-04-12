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

  before_create :updated_matching, :update_next_run_at
  before_update :updated_matching, :update_next_run_at

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
    day_map = {
      0 => 'Sun',
      1 => 'Mon',
      2 => 'Tue',
      3 => 'Wed',
      4 => 'Thu',
      5 => 'Fri',
      6 => 'Sat',
    }

    # check day
    return false if !timeplan['days']
    return false if !timeplan['days'][day_map[time.wday]]

    # check hour
    return false if !timeplan['hours']
    return false if !timeplan['hours'][time.hour.to_s] && !timeplan['hours'][time.hour]

    # check min
    return false if !timeplan['minutes']
    return false if !timeplan['minutes'][match_minutes(time.min).to_s] && !timeplan['minutes'][match_minutes(time.min)]

    true
  end

  def matching_count
    ticket_count, _tickets = Ticket.selectors(condition, limit: 1, execution_time: true)
    ticket_count || 0
  end

  def next_run_at_calculate(time = Time.zone.now)
    if last_run_at
      diff = time - last_run_at
      if diff.positive?
        time = time + 10.minutes
      end
    end
    day_map = {
      0 => 'Sun',
      1 => 'Mon',
      2 => 'Tue',
      3 => 'Wed',
      4 => 'Thu',
      5 => 'Fri',
      6 => 'Sat',
    }
    return nil if !active
    return nil if !timeplan['days']
    return nil if !timeplan['hours']
    return nil if !timeplan['minutes']

    # loop week days
    (0..7).each do |day_counter|
      time_to_check = nil
      day_to_check = if day_counter.zero?
                       time
                     else
                       time + 1.day
                     end
      if !timeplan['days'][day_map[day_to_check.wday]]

        # start on next day at 00:00:00
        time = day_to_check - day_to_check.sec.seconds
        time = time - day_to_check.min.minutes
        time = time - day_to_check.hour.hours
        next
      end

      min = day_to_check.min
      min = if min < 10
              0
            elsif min < 20
              10
            elsif min < 30
              20
            elsif min < 40
              30
            elsif min < 50
              40
            else
              50
            end

      # move to [0-5]0:00 time stamps
      day_to_check = day_to_check - day_to_check.min.minutes + min.minutes
      day_to_check = day_to_check - day_to_check.sec.seconds

      # loop minutes till next full hour
      if day_to_check.min.nonzero?
        (0..5).each do |minute_counter|
          if minute_counter.nonzero?
            break if day_to_check.min.zero?

            day_to_check = day_to_check + 10.minutes
          end
          next if !timeplan['hours'][day_to_check.hour] && !timeplan['hours'][day_to_check.hour.to_s]
          next if !timeplan['minutes'][match_minutes(day_to_check.min)] && !timeplan['minutes'][match_minutes(day_to_check.min).to_s]

          return day_to_check
        end
      end

      # loop hours
      hour_to_check = nil
      (0..23).each do |hour_counter|
        hour_to_check = day_to_check + hour_counter.hours

        # start on next day
        if hour_to_check.day != day_to_check.day
          time = day_to_check - day_to_check.hour.hours
          break
        end

        # ignore not configured hours
        next if !timeplan['hours'][hour_to_check.hour] && !timeplan['hours'][hour_to_check.hour.to_s]
        return nil if !hour_to_check

        # loop minutes
        minute_to_check = nil
        (0..5).each do |minute_counter|
          minute_to_check = hour_to_check + minute_counter.minutes * 10
          next if !timeplan['minutes'][match_minutes(minute_to_check.min)] && !timeplan['minutes'][match_minutes(minute_to_check.min).to_s]

          time_to_check = minute_to_check
          break
        end
        next if !minute_to_check

        return time_to_check
      end

    end
    nil
  end

  private

  def updated_matching
    self.matching = matching_count
    true
  end

  def update_next_run_at
    self.next_run_at = next_run_at_calculate
    true
  end

  def match_minutes(minutes)
    return 0 if minutes < 10

    "#{minutes.to_s.gsub(%r{(\d)\d}, '\\1')}0".to_i
  end

end
