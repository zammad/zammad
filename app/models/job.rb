# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Job < ApplicationModel
  include ChecksClientNotification
  include ChecksConditionValidation

  load 'job/assets.rb'
  include Job::Assets

  store     :timeplan
  store     :condition
  store     :perform
  validates :name, presence: true

  before_create :updated_matching, :update_next_run_at
  before_update :updated_matching, :update_next_run_at

  def self.run
    jobs = Job.where(active: true, running: false)
    jobs.each do |job|
      logger.debug "Execute job #{job.inspect}"

      next if !job.executable?

      matching = job.matching_count
      if job.matching != matching
        job.matching = matching
        job.save
      end

      next if !job.in_timeplan?

      # find tickets to change
      ticket_count, tickets = Ticket.selectors(job.condition, 2_000)

      logger.debug "Job #{job.name} with #{ticket_count} tickets"

      job.processed = ticket_count || 0
      job.running = true
      job.save

      if tickets
        tickets.each do |ticket|
          Transaction.execute(disable_notification: job.disable_notification, reset_user_id: true) do
            ticket.perform_changes(job.perform, 'job')
          end
        end
      end

      job.running = false
      job.last_run_at = Time.zone.now
      job.save
    end
    true
  end

  def executable?
    return false if !active

    # only execute jobs, older then 1 min, to give admin posibility to change
    return false if updated_at > Time.zone.now - 1.minute

    # check if jobs need to be executed
    # ignore if job was running within last 10 min.
    return false if last_run_at && last_run_at > Time.zone.now - 10.minutes

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
    ticket_count, tickets = Ticket.selectors(condition, 1)
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
      if min < 9
        min = 0
      elsif min < 20
        min = 10
      elsif min < 30
        min = 20
      elsif min < 40
        min = 30
      elsif min < 50
        min = 40
      elsif min < 60
        min = 50
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
    "#{minutes.to_s.gsub(/(\d)\d/, '\\1')}0".to_i
  end

end
