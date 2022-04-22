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

  # Similar to #travel_to, but fakes browser (frontend) time.
  # Useful when testing time that is generated in frontend
  def browser_travel_to(time)
    execute_script <<~JAVASCRIPT
      // load sinon if it's not already loaded
      if(typeof sinon == 'undefined') {
        var script = document.createElement( 'script' );
        script.type = 'text/javascript';
        script.src = '/assets/tests/sinon-9.2.4.js';
        $('head').append( script );
      }

      window.clock = sinon.useFakeTimers({now: new Date(#{time.to_i * 1_000}), toFake: ['Date']})
    JAVASCRIPT
  end
end

RSpec.configure do |config|
  # make usage of time travel helpers possible
  config.include ActiveSupport::Testing::TimeHelpers
  config.include TimeHelperCache
end
