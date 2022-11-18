# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module TimeHelperCache
  %w[travel travel_to freeze_time travel_back].each do |method_name|
    define_method method_name do |*args, **kwargs, &blk|
      super(*args, **kwargs, &blk).tap do
        Rails.cache.clear
        Setting.class_variable_set :@@last_changed_at, 1.second.ago # rubocop:disable Style/ClassVars
      end
    end
  end

  # Similar to #travel_to, but fakes browser (frontend) time.
  # Useful when testing time that is generated in frontend
  def browser_travel_to(time)
    execute_script "window.clock = sinon.useFakeTimers({now: new Date(#{time.to_i * 1_000}), toFake: ['Date']})"
  end
end

RSpec.configure do |config|
  # make usage of time travel helpers possible
  config.include ActiveSupport::Testing::TimeHelpers
  config.include TimeHelperCache
end
