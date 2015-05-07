module TimeCalculation

=begin

put working hours matrix and timezone in function, returns UTC working hours matrix

  working_hours_martix = TimeCalculation.working_hours('2013-10-27 20:00:15', working_hours_matrix, 'Europe/Berlin')

  working_hours_martix = {
    :Mon => [nil,nil,nil,nil,nil,nil,nil,nil,true,true,true,true,true,true,true,true,true,true,true,nil,nil,nil,nil,nil],
    :Tue => [nil,nil,nil,nil,nil,nil,nil,nil,true,true,true,true,true,true,true,true,true,true,true,nil,nil,nil,nil,nil],
    :Wed => [nil,nil,nil,nil,nil,nil,nil,nil,true,true,true,true,true,true,true,true,true,true,true,nil,nil,nil,nil,nil],
    :Thu => [nil,nil,nil,nil,nil,nil,nil,nil,true,true,true,true,true,true,true,true,true,true,true,nil,nil,nil,nil,nil],
    :Fri => [nil,nil,nil,nil,nil,nil,nil,nil,true,true,true,true,true,true,true,true,true,true,true,nil,nil,nil,nil,nil],
    :Sat => [],
    :Sun => [],
  }

=end

  def self.working_hours(start_time, config, timezone)
    time_diff = 0
    if timezone
      begin
        time_diff = Time.parse(start_time.to_s).in_time_zone(timezone).utc_offset
     rescue Exception => e
       Rails.logger.error "Can't fine tomezone #{timezone}"
       Rails.logger.error e.inspect
       Rails.logger.error e.backtrace
      end
    end
    beginning_of_workday = Time.parse("1977-10-27 #{config['beginning_of_workday']}")
    end_of_workday       = Time.parse("1977-10-27 #{config['end_of_workday']}") - 3600
    config_ok = false
    working_hours = {}
    [:Mon, :Tue, :Wed, :Thu, :Fri, :Sat, :Sun].each {|day|
      working_hours[day] = []

      next if !config[day.to_s]
      if config[day.to_s] != true && config[day.to_s] != day.to_s
        next
      end

      config_ok = true
      (0..23).each {|hour|
        time = Time.parse("1977-10-27 #{hour}:00:00")
        if time >= beginning_of_workday && time <= end_of_workday
          working_hours[day].push true
        else
          working_hours[day].push nil
        end
      }
    }

    if !config_ok
      raise 'sla config is invalid! ' + config.inspect
    end

    # shift working hours / if needed
    if time_diff && time_diff != 0

      hours_to_shift = (time_diff / 3600 ).round
      move_items = {
        Mon: [],
        Tue: [],
        Wed: [],
        Thu: [],
        Fri: [],
        Sat: [],
        Sun: [],
      }
      (1..hours_to_shift).each {|count|
        working_hours.each {|day, value|

          next if !working_hours[day]

          to_move = working_hours[day].shift
          if day == :Mon
            move_items[:Tue].push to_move
          elsif day == :Tue
            move_items[:Wed].push to_move
          elsif day == :Wed
            move_items[:Thu].push to_move
          elsif day == :Thu
            move_items[:Fri].push to_move
          elsif day == :Fri
            move_items[:Sat].push to_move
          elsif day == :Sat
            move_items[:Sun].push to_move
          elsif day == :Sun
            move_items[:Mon].push to_move
          end
        }
      }
      move_items.each {|day, value|
        value.each {|item|
          working_hours[day].push item
        }
      }
    end
    working_hours
  end

=begin

  returns business hours in minutes between to dates

  business_hours_in_min = Time.Calculation.business_time_diff(
    '2013-10-27 14:00:15',
    '2013-10-27 18:10:15',
    working_hours_martix,
    'Europe/Berlin',
  )

=end

  def self.business_time_diff(start_time, end_time, config = nil, timezone = '')
    if start_time.class == String
      start_time  = Time.parse( start_time.to_s + 'UTC' )
    end
    if end_time.class == String
      end_time = Time.parse( end_time.to_s + 'UTC' )
    end

    # if no config is given, just return calculation directly
    if !config
      return ((end_time - start_time) / 60 ).round
    end

    working_hours = self.working_hours(start_time, config, timezone)

    week_day_map = {
      1 => :Mon,
      2 => :Tue,
      3 => :Wed,
      4 => :Thu,
      5 => :Fri,
      6 => :Sat,
      0 => :Sun,
    }

    count = 0
    calculation = true
    first_loop  = true
    while calculation
      week_day = start_time.wday
      day      = start_time.day
      month    = start_time.month
      year     = start_time.year
      hour     = start_time.hour

      # check if it's vacation day
      if config
        if config['holidays']
          if config['holidays'].include?("#{year}-#{month}-#{day}")

            # jump to next day
            start_time = start_time.beginning_of_day + 86_400
            next
          end
        end
      end

      # check if it's countable day
      if working_hours[ week_day_map[week_day] ].empty?

        # jump to next day
        start_time = start_time.beginning_of_day + 86_400
        next
      end

      # fillup to first full hour
      if first_loop
        diff = end_time - start_time

        if diff > 59 * 60
          diff = start_time - start_time.beginning_of_hour
        end
        start_time += diff

        # check if it's countable hour
        if working_hours[ week_day_map[week_day] ][ hour ]
          count += diff
        end
      end
      first_loop = false

      # loop to next hour
      (hour..23).each { |next_hour|

        # check if end time is lower
        if start_time >= end_time
          calculation = false
          break
        end

        # check if end_time is within this hour
        diff = end_time - start_time
        if diff > 59 * 60
          diff = 3600
        end

        # keep it in current day
        if next_hour == 23
          start_time += diff - 1
        else
          start_time += diff
        end

        # check if it's business hour and count
        if working_hours[ week_day_map[week_day] ][ next_hour ]
          count += diff
        end
      }

      # loop to next day
      start_time = start_time.beginning_of_day + 86_400
    end

    diff = count / 60
    diff.round
  end

=begin

  returns destination date of start time plus X minutes

  dest_time = Time.Calculation.dest_time(
    '2013-10-27 14:00:15',
    120,
    working_hours_martix,
    'Europe/Berlin',
  )

=end

  def self.dest_time(start_time, diff_in_min, config = nil, timezone = '')
    if start_time.class == String
      start_time = Time.parse( start_time.to_s + ' UTC' )
    end

    return start_time if diff_in_min == 0

    # if no config is given, just return calculation directly
    if !config
      return start_time + (diff_in_min * 60)
    end

    # loop
    working_hours = self.working_hours(start_time, config, timezone)

    week_day_map = {
      1 => :Mon,
      2 => :Tue,
      3 => :Wed,
      4 => :Thu,
      5 => :Fri,
      6 => :Sat,
      0 => :Sun,
    }

    count       = diff_in_min * 60
    calculation = true
    first_loop  = true
    while calculation
      week_day = start_time.wday
      day      = start_time.day
      month    = start_time.month
      year     = start_time.year
      hour     = start_time.hour
#puts "start outer loop #{start_time}-#{week_day}-#{year}-#{month}-#{day}-#{hour}|c#{count}"

      # check if it's vacation day
      if config
        if config['holidays']
          if config['holidays'].include?("#{year}-#{month}-#{day}")

            # jump to next day
            start_time = start_time.beginning_of_day + 86_400
            next
          end
        end
      end

      # check if it's countable day
      if working_hours[ week_day_map[week_day] ].empty?

        # jump to next day
        start_time = start_time.beginning_of_day + 86_400
        next
      end

      # fillup to first full hour
      if first_loop

        # get rest of this hour if diff_in_min in lower the one hour
        diff_to_count = 3600
        if diff_to_count > (diff_in_min * 60)
          diff_to_count = diff_in_min * 60
        end
        diff = diff_to_count - (start_time - start_time.beginning_of_hour)
        start_time += diff

        # check if it's countable hour
        if working_hours[ week_day_map[week_day] ][ hour ]
          count -= diff
        end

        # start on next hour of we moved to next
        if diff != 0
          hour += 1
        end
      end

      first_loop = false

      # loop to next hour
      (hour..23).each { |next_hour|

        diff = 3600

        # check if count positiv
        if count <= 0
          calculation = false
          break
        end

        # check if it's business hour and count
        if working_hours[ week_day_map[week_day] ][ next_hour ]

          # check if count is within this hour
          if count > 59 * 60
            diff = 3600
          else
            diff = count
          end
          count -= diff
        end

        # keep it in current day
        if next_hour == 23
          start_time += diff - 1
        else
          start_time += diff
        end
      }

      # check if count positiv
      if count <= 0
        calculation = false
        break
      end

      # loop to next day
      start_time = start_time.beginning_of_day + 86_400
    end

    start_time
  end

end
