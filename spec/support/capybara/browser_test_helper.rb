module BrowserTestHelper

  # Finds an element and clicks it - wrapped in one method.
  #
  # @example
  #  click('.js-channel .btn.email')
  #
  #  click(:href, '#settings/branding')
  #
  def click(*args)
    find(*args).click
  end

  # This is a wrapper around the Selenium::WebDriver::Wait class
  # with additional methods.
  # @see BrowserTestHelper::Waiter
  #
  # @example
  #  wait(5).until { ... }
  #
  # @example
  #  wait(5, interval: 0.5).until { ... }
  #
  def wait(seconds = Capybara.default_max_wait_time, **kargs)
    wait_args   = Hash(kargs).merge(timeout: seconds)
    wait_handle = Selenium::WebDriver::Wait.new(wait_args)
    Waiter.new(wait_handle)
  end

  class Waiter < SimpleDelegator

    # This method is a derivation of Selenium::WebDriver::Wait#until
    # which ignores Capybara::ElementNotFound exceptions raised
    # in the given block.
    #
    # @example
    #  wait(5).until_exists { find('[data-title="example"]') }
    #
    def until_exists
      self.until do
        begin
          yield
        rescue Capybara::ElementNotFound # rubocop:disable Lint/HandleExceptions
        end
      end
    rescue Selenium::WebDriver::Error::TimeOutError => e
      # cleanup backtrace
      e.set_backtrace(e.backtrace.drop(3))
      raise e
    end

    # This method loops a given block until the result of it is constant.
    #
    # @example
    #  wait(5).until_constant { find('.total').text }
    #
    def until_constant
      previous = nil
      loop do
        sleep __getobj__.instance_variable_get(:@interval)
        latest = yield
        break if latest == previous

        previous = latest
      end
    end
  end
end

RSpec.configure do |config|
  config.include BrowserTestHelper, type: :system
end
