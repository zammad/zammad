module IceCube

  class MonthlyRule < ValidatedRule

    include Validations::MonthlyInterval

    def initialize(interval = 1)
      super
      interval(interval)
      schedule_lock(:day, :hour, :min, :sec)
      reset
    end

  end

end
