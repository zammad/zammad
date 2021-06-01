# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module BrowserTestHelper

  # Sometimes tests refer to elements that get removed/re-added to the DOM when
  # updating the UI. This causes Selenium to throw a StaleElementReferenceError exception.
  # This method catches this error and retries the given amount of times re-raising
  # the exception if the element is still stale.
  # @see https://developer.mozilla.org/en-US/docs/Web/WebDriver/Errors/StaleElementReference WebDriver definition
  #
  # @example
  #  retry_on_stale do
  #    find('.now-here-soon-gone').click
  #  end
  #
  #  retry_on_stale(retries: 10) do
  #    find('.now-here-soon-gone').click
  #  end
  #
  # @raise [Selenium::WebDriver::Error::StaleElementReferenceError] If element is still stale after given number of retries
  def retry_on_stale(retries: 3)
    tries ||= 0

    yield
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    raise if tries == retries

    wait_time = tries
    tries += 1

    Rails.logger.info "Stale element found. Retry #{tries}/retries (sleeping: #{wait_time})"
    sleep wait_time
  end

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

  # Moves the mouse to element.
  #
  # @example
  # move_mouse_to(page.find('button.hover_me'))
  #
  def move_mouse_to(element)
    element.in_fixed_position
    page.driver.browser.action.move_to_location(element.native.location.x, element.native.location.y).perform
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
