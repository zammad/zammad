# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module TimeHelperCache
  def travel(...)
    super.tap do
      Rails.cache.clear
    end
  end

  def travel_to(...)
    super.tap do
      Rails.cache.clear
    end
  end

  def freeze_time(...)
    super.tap do
      Rails.cache.clear
    end
  end

  def travel_back(...)
    super.tap do
      Rails.cache.clear
    end
  end
end

RSpec.configure do |config|
  # make usage of time travel helpers possible
  config.include ActiveSupport::Testing::TimeHelpers
  config.include TimeHelperCache
end
