module IceCube

  class DailyRule < ValidatedRule

    include Validations::DailyInterval

    def initialize(interval = 1)
      super
      interval(interval)
      schedule_lock(:hour, :min, :sec)
      reset
    end

  end

end
