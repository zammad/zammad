# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module TimeHelperCache
  %w[travel travel_to freeze_time travel_back].each do |method_name|
    define_method method_name do |*args, **kwargs, &blk|
      super(*args, **kwargs, &blk).tap do
        Rails.cache.clear
      rescue Errno::EISDIR
        # suppress race condition errors
      ensure
        Setting.class_variable_set :@@last_changed_at, 1.second.ago # rubocop:disable Style/ClassVars
      end
    end
  end

  # Similar to #travel_to, but fakes browser (frontend) time.
  # Useful when testing time that is generated in frontend
  #
  # KeyUp event is triggered to update activity timestamp in the frontend.
  # Otherwise Capybara session may get logged out.
  # @see app/assets/javascripts/app/controllers/_plugin/session_timeout.coffee`)
  def browser_travel_to(time)
    target_time = time.to_i * 1_000
    execute_script "App.Plugin.instance().backend.session_timeout.lastEvent = #{target_time}"
    execute_script "window.clock = sinon.useFakeTimers({now: new Date(#{target_time}), toFake: ['Date']})"
  end

  # Reimplementation of `setMonth(month[, date])` from the ECMAScript specification.
  #   https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-date.prototype.setmonth
  def frontend_relative_month(obj, month, date = nil, year: nil)
    # 1. Let t be ? thisTimeValue(this value).
    t = obj

    # 2. Let m be ? ToNumber(month).
    m = month.to_i

    # 3. If date is present, let dt be ? ToNumber(date).
    if date.present?
      dt = date.to_i
    end

    # 4. If t is NaN, return NaN.
    raise InvalidDate if !t.is_a?(Time)

    # 5. Set t to LocalTime(t).
    t = t.in_time_zone

    # 6. If date is not present, let dt be DateFromTime(t).
    if date.nil?
      dt = t.day
    end

    # 7. Let newDate be MakeDate(MakeDay(YearFromTime(t), m, dt), TimeWithinDay(t)).
    new_year = t.year
    new_month = t.month + m
    if new_month > 12
      new_year += 1
      new_month -= 12
    end

    new_year += year if year

    Time.zone.local(new_year, new_month, dt, t.hour, t.min, t.sec)

    # Ignore the rest, as `Time#local` already handles it correctly:
    #   8. Let u be TimeClip(UTC(newDate)).
    #   9. Set the [[DateValue]] internal slot of this Date object to u.
    #   10. Return u.

  end
end

RSpec.configure do |config|
  # make usage of time travel helpers possible
  config.include ActiveSupport::Testing::TimeHelpers
  config.include TimeHelperCache
end
