# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Job < ApplicationModel
  store     :timeplan
  store     :condition
  store     :perform
  validates :name, presence: true

  before_create :updated_matching
  before_update :updated_matching

  notify_clients_support

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
          logger.debug "Perform job #{job.perform.inspect} in Ticket.find(#{ticket.id})"
          changed = false
          job.perform.each do |key, value|
            (object_name, attribute) = key.split('.', 2)
            raise "Unable to update object #{object_name}.#{attribute}, only can update tickets!" if object_name != 'ticket'

            next if ticket[attribute].to_s == value['value'].to_s
            changed = true

            ticket[attribute] = value['value']
            logger.debug "set #{object_name}.#{attribute} = #{value['value'].inspect}"
          end
          next if !changed
          ticket.updated_by_id = 1
          ticket.save
        end
      end

      job.running = false
      job.last_run_at = Time.zone.now
      job.save
    end
    true
  end

  def executable?

    # only execute jobs, older then 1 min, to give admin posibility to change
    return false if updated_at > Time.zone.now - 1.minute

    # check if jobs need to be executed
    # ignore if job was running within last 10 min.
    return false if last_run_at && last_run_at > Time.zone.now - 10.minutes

    true
  end

  def in_timeplan?
    time    = Time.zone.now
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

  private

  def updated_matching
    self.matching = matching_count
  end

  def match_minutes(minutes)
    return 0 if minutes < 10
    "#{minutes.to_s.gsub(/(\d)\d/, '\\1')}0".to_i
  end

end
