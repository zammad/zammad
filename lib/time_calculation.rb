require 'business_time'
require 'business_time/business_minutes'
require 'business_time/core_ext/fixnum_minute'
require 'business_time/core_ext/time_fix'

module TimeCalculation
  def self.config(config)
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
    start_time  = Time.parse( start_time.to_s + 'UTC' )
    end_time    = Time.parse( end_time.to_s + 'UTC' )
    diff = start_time.business_time_until( end_time ) / 60
    diff.round
  end

  def self.dest_time(start_time, diff_in_min)
    start_time_string = start_time.to_s
    if start_time.to_s != /UTC/
      start_time_string +=  ' UTC'
    end
    start_time = Time.parse( start_time_string )
    dest_time = diff_in_min.round.business_minute.after( start_time )
    return dest_time
  end

end
