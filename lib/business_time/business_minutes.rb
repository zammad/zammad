module BusinessTime

  class BusinessMinutes
    def initialize(minutes)
      @minutes = minutes
    end

    def ago
      Time.zone ? before(Time.zone.now) : before(Time.now)
    end

    def from_now
      Time.zone ?  after(Time.zone.now) : after(Time.now)
    end

    def after(time)
      after_time = Time.roll_forward(time)
      # Step through the minutes, skipping over non-business minutes
      days = @minutes / 60 / 24
      hours = ( @minutes - ( days * 60 * 24 ) ) / 60
      minutes =  @minutes - ( (days * 60 * 24 ) + (hours * 60) )
      if @minutes > 60 * 12
        
      end

      local_sec = @minutes * 60
      loop = true
      while (loop == true) do
        a = after_time
        if local_sec >= 60 * 60
          after_time = after_time + 1.hour
        else
          after_time = after_time + 1.minute
        end

        # Ignore minutes before opening and after closing
        if (after_time > Time.end_of_workday(after_time))
          after_time = after_time + off_minutes
          if local_sec < 60 * 60
            after_time = after_time - 60
          else
            after_time = after_time - 60 * 60
          end
          next
        end

        # Ignore weekends and holidays
        while !Time.workday?(after_time)
          after_time = Time.beginning_of_workday(after_time + 1.day)
          a = after_time
        end
        diff = after_time - a
        local_sec = local_sec - diff

        if local_sec <= 0
          loop = false
          next
        end

      end
      after_time
    end
    alias_method :since, :after

    def before(time)
      before_time = Time.roll_forward(time)
      # Step through the hours, skipping over non-business hours
      @minutes.times do
        before_time = before_time - 1.minute

        # Ignore hours before opening and after closing
        if (before_time < Time.beginning_of_workday(before_time))
          before_time = before_time - off_minutes
        end

        # Ignore weekends and holidays
        while !Time.workday?(before_time)
          before_time = before_time - 1.day
        end
      end
      before_time
    end

    private

    def off_minutes
      return @gap if @gap
      if Time.zone
        gap_end = Time.zone.parse(BusinessTime::Config.beginning_of_workday)
        gap_begin = (Time.zone.parse(BusinessTime::Config.end_of_workday)-1.day)
      else
        gap_end = Time.parse(BusinessTime::Config.beginning_of_workday)
        gap_begin = (Time.parse(BusinessTime::Config.end_of_workday) - 1.day)
      end
      @gap = gap_end - gap_begin
    end
  end

end
