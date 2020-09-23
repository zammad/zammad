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

  # This checks the number of queued AJAX requests in the frontend JS app
  # and assures that the number is constantly zero for 0.5 seconds.
  # It comes in handy when waiting for AJAX requests to be completed
  # before performing further actions.
  #
  # @example
  #  await_empty_ajax_queue
  #
  def await_empty_ajax_queue
    wait(5, interval: 0.5).until_constant do
      page.evaluate_script('App.Ajax.queue().length').zero?
    end
  end

  # Moves the mouse from its current position by the given offset.
  # If the coordinates provided are outside the viewport (the mouse will end up outside the browser window)
  # then the viewport is scrolled to match.
  #
  # @example
  # move_mouse_by(x, y)
  # move_mouse_by(100, 200)
  #
  def move_mouse_by(x_axis, y_axis)
    page.driver.browser.action.move_by(x_axis, y_axis).perform
  end

  # Clicks and hold (without releasing) in the middle of the given element.
  #
  # @example
  # click_and_hold(ticket)
  # click_and_hold(tr[data-id='1'])
  #
  def click_and_hold(element)
    page.driver.browser.action.click_and_hold(element).perform
  end

  # Releases the depressed left mouse button at the current mouse location.
  #
  # @example
  # release_mouse
  #
  def release_mouse
    page.driver.browser.action.release.perform
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

        yield
      rescue Capybara::ElementNotFound
        # doesn't exist yet
      end
    rescue Selenium::WebDriver::Error::TimeOutError => e
      # cleanup backtrace
      e.set_backtrace(e.backtrace.drop(3))
      raise e
    end

    # This method is a derivation of Selenium::WebDriver::Wait#until
    # which ignores Capybara::ElementNotFound exceptions raised
    # in the given block.
    #
    # @example
    #  wait(5).until_disappear { find('[data-title="example"]') }
    #
    def until_disappears
      self.until do

        yield
        false
      rescue Capybara::ElementNotFound
        true
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
      timeout  = __getobj__.instance_variable_get(:@timeout)
      interval = __getobj__.instance_variable_get(:@interval)
      rounds   = (timeout / interval).to_i

      rounds.times do
        sleep interval

        latest = yield

        next if latest.nil?
        break if latest == previous

        previous = latest
      end
    end
  end
end

RSpec.configure do |config|
  config.include BrowserTestHelper, type: :system
end
