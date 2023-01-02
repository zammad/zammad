# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  # Get the current cookies from the browser with the driver object.
  #
  def cookies
    page.driver.browser.manage.all_cookies
  end

  # Get a single cookie by the given name (regex possible)
  #
  # @example
  #  cookie('cookie-name')
  #
  def cookie(name)
    cookies.find { |cookie| cookie[:name].match?(name) }
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

  # Finds svg icon in Mobile View
  #
  # @example
  #  icon = find_icon('home')
  #  icon.click
  #
  def find_icon(name)
    find("[href=\"#icon-#{name}\"]").find(:xpath, '..')
  end

  # This is a wrapper around the Selenium::WebDriver::Wait class
  # with additional methods.
  # @see BrowserTestHelper::Waiter
  #
  # @example
  #  wait.until { ... }
  #
  # @example
  #  wait(5, interval: 0.5).until { ... }
  #
  def wait(seconds = Capybara.default_max_wait_time, **kargs)
    wait_args   = Hash(kargs).merge(timeout: seconds)
    wait_handle = Selenium::WebDriver::Wait.new(wait_args)
    Waiter.new(wait_handle)
  end

  # This checks the number of queued AJAX requests in the frontend JS is zero.
  # It comes in handy when waiting for AJAX requests to be completed
  # before performing further actions.
  #
  # @example
  #  await_empty_ajax_queue
  #
  def await_empty_ajax_queue

    # Waiting not supported/required by mobile app.
    return if self.class.metadata[:app] == :mobile # self.class needed to get metadata from within an `it` block.

    # page.evaluate_script silently discards any present alerts, which is not desired.
    begin
      return if page.driver.browser.switch_to.alert
    rescue Selenium::WebDriver::Error::NoSuchAlertError # rubocop:disable Lint/SuppressedException
    end

    # skip on non app related context
    return if page.evaluate_script('typeof(App) !== "function" || typeof($) !== "function"')

    # Always wait a little bit to allow for triggering of requests.
    sleep 0.1

    wait(5).until do
      page.evaluate_script('App.Ajax.queue().length === 0 && $.active === 0 && Object.keys(App.FormHandlerCoreWorkflow.getRequests()).length === 0').eql? true
    end
  rescue Selenium::WebDriver::Error::TimeoutError
    nil # There may be cases when the default wait time is not enough.
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

  # Clicks and hold (without releasing) in the middle of the given element
  # and moves it to the top left of the page to show marcos batches in
  # overview section.
  #
  # @example
  # display_macro_batches(Ticket.first)
  #
  def display_macro_batches(ticket)

    # Get the ticket row DOM element
    element = page.find(:table_row, ticket.id).native

    # Drag the element to the top of the screen, in order to display macro batches.
    #  First, move the mouse to the middle left part of the element to avoid popups interfering with the action.
    #  Then, click and hold the left mouse button.
    #  Next, move the mouse vertically, just below the top edge of the browser.
    #  Finally, move the mouse slightly horizontally to simulate a non-linear drag.
    page.driver.browser.action
      .move_to_location(element.location.x + 50, element.location.y + 10)
      .click_and_hold
      .move_by(0, -element.location.y + 3)
      .move_by(3, 0)
      .perform
  end

  # Releases the depressed left mouse button at the current mouse location.
  #
  # @example
  # release_mouse
  #
  def release_mouse
    page.driver.browser.action.release.perform
    await_empty_ajax_queue
  end

  class Waiter < SimpleDelegator

    # This method is a derivation of Selenium::WebDriver::Wait#until
    # which ignores Capybara::ElementNotFound exceptions raised
    # in the given block.
    #
    # @example
    #  wait.until_exists { find('[data-title="example"]') }
    #
    def until_exists
      self.until do

        yield
      rescue Capybara::ElementNotFound
        # doesn't exist yet
      end
    rescue Selenium::WebDriver::Error::TimeoutError => e
      # cleanup backtrace
      e.set_backtrace(e.backtrace.drop(3))
      raise e
    end

    # This method is a derivation of Selenium::WebDriver::Wait#until
    # which ignores Capybara::ElementNotFound exceptions raised
    # in the given block.
    #
    # @example
    #  wait.until_disappear { find('[data-title="example"]') }
    #
    def until_disappears
      self.until do

        yield
        false
      rescue Capybara::ElementNotFound
        true
      end
    rescue Selenium::WebDriver::Error::TimeoutError => e
      # cleanup backtrace
      e.set_backtrace(e.backtrace.drop(3))
      raise e
    end

    # This method loops a given block until the result of it is constant.
    #
    # @example
    #  wait.until_constant { find('.total').text }
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
