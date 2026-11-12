# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Calendar::Ical::Fetch < Service::Base
  attr_reader :url

  def initialize(url:)
    @url = url
  end

  def execute
    result = UserAgent.get(url, {}, { validate_safety: { allow_private: true } })
    raise result.error if !result.success?

    result.body
  end
end
