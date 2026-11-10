# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module PlaywrightNative
  # The app sets test flags (window.testFlags) once it is done with something, e.g. a query.
  module TestFlags
    def wait_for_test_flag(flag, skip_clearing: false)
      page.wait_for_function(
        '([flag, skipClearing]) => window.testFlags && window.testFlags.get(flag, skipClearing)',
        arg: [flag, skip_clearing],
      )
    rescue Playwright::TimeoutError
      raise "Test flag #{flag} not set"
    end

    # Unlike wait_for_test_flag, it neither waits nor clears the flag.
    def test_flag_set?(flag)
      page.evaluate('(flag) => window.testFlags.get(flag, true)', arg: flag)
    end

    def wait_for_query(name, number: 1, skip_clearing: false)
      wait_for_test_flag("__gql query #{name} #{number}", skip_clearing:)
    end

    def wait_for_mutation(name, number: 1, skip_clearing: false)
      wait_for_test_flag("__gql mutation #{name} #{number}", skip_clearing:)
    end

    # The start flag only means the client got the first answer, the server may not listen yet.
    def wait_for_subscription_start(name, entity: nil, scope: nil)
      wait_for_test_flag("__gql subscription #{name} start", skip_clearing: true)
      wait_until("GraphQL event stream for subscription #{name} has no subscriber") { GraphqlEventStream.subscribed?(name, entity:, scope:) }
    end

    def wait_for_form_to_settle(form)
      wait_for_test_flag("#{form}.settled")
    end

    # Typing into an editor before it is ready may get lost. The flag is set once per editor.
    def wait_for_editor_ready(textbox)
      wait_for_test_flag("#{textbox.get_attribute('data-form-id')}.#{textbox.get_attribute('name')}.editor.ready", skip_clearing: true)
    end

    # For state outside the browser, e.g. the database.
    def wait_until(message = 'Condition not met', timeout: PLAYWRIGHT_TIMEOUT)
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

      until yield
        raise message if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

        sleep 0.1
      end
    end
  end
end

RSpec.configure do |config|
  config.include PlaywrightNative::TestFlags, type: :playwright
end
