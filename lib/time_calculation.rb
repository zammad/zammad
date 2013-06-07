require 'business_time'
require 'business_time/business_minutes'
require 'business_time/core_ext/fixnum_minute'
require 'business_time/core_ext/time_fix'

module TimeCalculation
  def self.config(config, timezone, start_time)
    time_diff = 0
    if timezone
      begin
         time_diff = Time.parse(start_time.to_s).in_time_zone(timezone).utc_offset
      rescue Exception => e
        puts "ERROR: Can't fine tomezone #{timezone}"
        puts e.inspect
        puts e.backtrace
      end
    end
    beginning_of_workday = Time.parse("1977-10-27 #{config['beginning_of_workday']}") + time_diff
    if beginning_of_workday
      config['beginning_of_workday'] = "#{beginning_of_workday.hour}:#{beginning_of_workday.min}"
    end
    end_of_workday = Time.parse("1977-10-27 #{config['end_of_workday']}") + time_diff
    if end_of_workday
      config['end_of_workday'] = "#{end_of_workday.hour}:#{end_of_workday.min}"
    end
    BusinessTime::Config.beginning_of_workday = config['beginning_of_workday']
    BusinessTime::Config.end_of_workday       = config['end_of_workday']
    days = []
    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].each {|day|
      if config[day]
        days.push day.downcase.to_sym
      end
    }
    BusinessTime::Config.work_week = days
    holidays = []
    if config['holidays']
      config['holidays'].each {|holiday|
        date = Date.parse( holiday )
        holidays.push date.to_date
      }
    end
    BusinessTime::Config.holidays = holidays
  end

  def self.business_time_diff(start_time, end_time)
    if start_time.class == String
      start_time  = Time.parse( start_time.to_s + 'UTC' )
    end
    if end_time.class == String
      end_time = Time.parse( end_time.to_s + 'UTC' )
    end
    diff = start_time.business_time_until( end_time ) / 60
    diff.round
  end

  def self.dest_time(start_time, diff_in_min)
    if start_time.class == String
      start_time = Time.parse( start_time.to_s + ' UTC' )
    end
    dest_time = diff_in_min.round.business_minute.after( start_time )
    return dest_time
  end

end
