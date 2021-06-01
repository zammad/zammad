# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Required workaround to serialize ActiveSupport::TimeWithZone, Time, Date and DateTime for ActiveJob
# until Rails 6 is used. See:
# - https://github.com/rails/rails/issues/18519
# - https://github.com/rails/rails/pull/32026
# - https://github.com/rails/rails/tree/6-0-stable/activejob/lib/active_job/serializers

class ActiveSupport::TimeWithZone
  include GlobalID::Identification

  alias id iso8601

  def self.find(iso8601)
    Time.iso8601(iso8601).in_time_zone
  end
end

class Time
  include GlobalID::Identification

  alias id iso8601

  def self.find(iso8601)
    Time.iso8601(iso8601)
  end
end

class Date
  include GlobalID::Identification

  alias id iso8601

  def self.find(iso8601)
    Date.iso8601(iso8601)
  end
end

class DateTime
  include GlobalID::Identification

  alias id iso8601

  def self.find(iso8601)
    DateTime.iso8601(iso8601)
  end
end
