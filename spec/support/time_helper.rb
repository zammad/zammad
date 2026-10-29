# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
end

RSpec.configure do |config|
  # make usage of time travel helpers possible
  config.include ActiveSupport::Testing::TimeHelpers
  config.include TimeHelperCache
end
