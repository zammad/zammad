# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Job < ApplicationModel
  store     :timeplan
  store     :condition
  store     :execute
  validates :name, presence: true

  before_create   :updated_matching
  before_update   :updated_matching

  notify_clients_support

  def self.run
    time    = Time.zone.now
    day_map = {
      0 => 'sun',
      1 => 'mon',
      2 => 'tue',
      3 => 'wed',
      4 => 'thu',
      5 => 'fri',
      6 => 'sat',
    }
    jobs = Job.where( active: true )
    jobs.each do |job|

      # only execute jobs, older then 1 min, to give admin posibility to change
      next if job.updated_at > Time.zone.now - 1.minute

      # check if jobs need to be executed
      # ignore if job was running within last 10 min.
      next if job.last_run_at && job.last_run_at > Time.zone.now - 10.minutes

      # check day
      next if !job.timeplan['days'].include?( day_map[time.wday] )

      # check hour
      next if !job.timeplan['hours'].include?( time.hour.to_s )

      # check min
      next if !job.timeplan['minutes'].include?( match_minutes(time.min.to_s) )

      # find tickets to change
      tickets = Ticket.where( job.condition.permit! )
                      .order( '`tickets`.`created_at` DESC' )
                      .limit( 1_000 )
      job.processed = tickets.count
      tickets.each do |ticket|
        logger.debug "CHANGE #{job.execute.inspect}"
        changed = false
        job.execute.each do |key, value|
          changed = true
          attribute = key.split('.', 2).last
          logger.debug "-- #{Ticket.columns_hash[ attribute ].type}"
          #value = 4
          #if Ticket.columns_hash[ attribute ].type == :integer
          #  logger.debug "to i #{attribute}/#{value.inspect}/#{value.to_i.inspect}"
          #  #value = value.to_i
          #end
          ticket[attribute] = value
          logger.debug "set #{attribute} = #{value.inspect}"
        end
        next if !changed
        ticket.updated_by_id = 1
        ticket.save
      end

      job.last_run_at = Time.zone.now
      job.save
    end
    true
  end

  private

  def updated_matching
    count = Ticket.where( condition.permit! ).count
    self.matching = count
  end

  def self.match_minutes(minutes)
    minutes.gsub!(/(\d)\d/, '\\1')
    minutes.to_s + '0'
  end
  private_class_method :match_minutes
end
