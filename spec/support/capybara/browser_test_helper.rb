# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module BrowserTestHelper # rubocop:disable Metrics/ModuleLength

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
  rescue Selenium::WebDriver::Error::StaleElementReferenceError, Capybara::Playwright::Node::StaleReferenceError
    raise if tries == retries

    wait_time = tries
    tries += 1

    Rails.logger.info "Stale element found. Retry #{tries}/#{retries} (sleeping: #{wait_time})"
    sleep wait_time

    retry
  end

  # Get the current cookies from the browser with the driver object.
  #
  def cookies
    if page.driver.is_a?(Capybara::Selenium::Driver)
      page.driver.browser.manage.all_cookies
    else
      page.driver.with_playwright_page do |pw_page|
        pw_page.context.cookies.map { |cookie| normalize_playwright_cookie(cookie) }
      end
    end
  end

  # Align the Playwright cookie shape with Selenium's: symbol keys and
  # expires as Time or nil (Playwright reports session cookies as -1).
  #
  def normalize_playwright_cookie(cookie)
    normalized = cookie.transform_keys { |key| key.underscore.to_sym }
    normalized[:expires] = normalized[:expires].negative? ? nil : Time.zone.at(normalized[:expires])
    normalized
  end

  # Get a single cookie by the given name (regex possible)
  #
  # @example
  #  cookie('cookie-name')
  #
  def cookie(name)
    cookies.find { |cookie| cookie[:name].match?(name) }
  end

  # Delete a single cookie by the given name (regex possible)
  #
  # @example
  #  delete_cookie('cookie-name')
  #
  def delete_cookie(name)
    cookie = cookie(name)

    return if !cookie

    if page.driver.is_a?(Capybara::Selenium::Driver)
      page.driver.browser.manage.delete_cookie(cookie[:name])
    else
      page.driver.with_playwright_page do |pw_page|
        pw_page.context.clear_cookies(name: cookie[:name])
      end
    end
  end

  # Finds an element and clicks it - wrapped in one method.
  #
  # @example
  #  click('.js-channel .btn.email')
  #
  #  click(:href, '#settings/branding')
  #
  def click(...)
    find(...).click
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
  def wait(seconds = Capybara.default_max_wait_time, **kwargs)
    wait_args   = Hash(kwargs).merge(timeout: seconds)
    wait_handle = Selenium::WebDriver::Wait.new(wait_args)
    Waiter.new(wait_handle)
  end

  # Setting's class-level cache can serve a stale value for a while after a write
  # (e.g. a real browser action, or this test's own Setting.set racing a concurrent
  # reader) - wait for our own read to settle on the expected value before relying on
  # frontend behavior that depends on it, rather than a blind sleep.
  #
  # Note: Setting.get round-trips hash values with string keys, even if the setting was
  # written with symbol keys - use `key:` to compare a specific key instead of the whole
  # hash if that's a concern.
  #
  # @example
  #  wait_for_setting('icinga_sender', icinga_sender)
  #
  # @example
  #  wait_for_setting('ai_assistance_ticket_summary_config', 'on_ticket_detail_opening', key: 'generate_on')
  #
  def wait_for_setting(name, value, key: nil)
    wait.until do
      current = Setting.get(name)
      current = current[key] if key
      current == value
    end
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
    return if %i[desktop_view mobile].include?(self.class.metadata[:app]) # self.class needed to get metadata from within an `it` block.

    # page.evaluate_script silently discards any present alerts, which is not desired.
    # PLAYWRIGHT PILOT: alert probing is Selenium-only (`browser` is private on the
    #   Playwright driver); Playwright handles dialogs via async handlers instead.
    if page.driver.is_a?(Capybara::Selenium::Driver)
      begin
        return if page.driver.browser.switch_to.alert
      rescue Selenium::WebDriver::Error::NoSuchAlertError # rubocop:disable Lint/SuppressedException
      end
    end

    # skip on non app related context
    return if page.evaluate_script('typeof(App) !== "function" || typeof($) !== "function"')

    # Always wait a little bit to allow for triggering of requests.
    sleep 0.1

    script_timeout_retried = false

    begin
      wait(5).until do
        page.evaluate_script('App.Ajax.queue().length === 0 && $.active === 0 && Object.keys(App.FormHandlerCoreWorkflow.getRequests()).length === 0').eql? true
      end
    rescue Selenium::WebDriver::Error::ScriptTimeoutError
      # The main thread was blocked by long-running synchronous work (e.g. drawing a huge
      #   inline image onto a canvas), so the check itself could not run. The browser is
      #   responsive again once the error surfaces - check once more before giving up.
      raise if script_timeout_retried

      script_timeout_retried = true
      retry
    end
  rescue Selenium::WebDriver::Error::TimeoutError, Selenium::WebDriver::Error::JavascriptError
    nil # Page may navigate away mid-check (e.g. SAML redirect), making App undefined.
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
    if page.driver.is_a?(Capybara::Selenium::Driver)
      page.driver.browser.action.move_by(x_axis, y_axis).perform
    else
      page.driver.with_playwright_page do |pw_page|
        position = playwright_mouse_position
        playwright_mouse_move(pw_page, position[:x] + x_axis, position[:y] + y_axis)
      end
    end
  end

  # Moves the mouse to element.
  #
  # @example
  # move_mouse_to(page.find('button.hover_me'))
  #
  def move_mouse_to(element)
    if page.driver.is_a?(Capybara::Selenium::Driver)
      element.in_fixed_position
      page.driver.browser.action.move_to_location(element.native.location.x, element.native.location.y).perform
    else
      page.driver.with_playwright_page do |pw_page|
        box = playwright_fixed_bounding_box(element)
        playwright_mouse_move(pw_page, box['x'], box['y'])
      end
    end
  end

  # Places the collapsed text cursor immediately before the given element by
  # setting the browser's Selection directly, instead of clicking at the
  # element's pixel location. A coordinate click is unreliable for a collapsed,
  # zero-content element such as the <br> of an empty line: Selenium and
  # Playwright's bundled Chromium report different bounding boxes for it (one
  # gives the real line height, the other collapses to 0), so identical click
  # coordinates can land on different lines depending on the driver.
  #
  # @example
  # place_cursor_before(blockquote_empty_line)
  #
  def place_cursor_before(element)
    page.execute_script(<<~JS, element.native)
      var range = document.createRange();
      range.setStartBefore(arguments[0]);
      range.collapse(true);

      var selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
    JS
  end

  # Clicks and hold (without releasing) in the middle of the given element.
  #
  # @example
  # click_and_hold(ticket)
  # click_and_hold(tr[data-id='1'])
  #
  def click_and_hold(element)
    if page.driver.is_a?(Capybara::Selenium::Driver)
      page.driver.browser.action.click_and_hold(element).perform
    else
      # element is the native node here, i.e. a Playwright::ElementHandle.
      page.driver.with_playwright_page do |pw_page|
        element.scroll_into_view_if_needed
        box = element.bounding_box
        playwright_mouse_move(pw_page, box['x'] + (box['width'] / 2), box['y'] + (box['height'] / 2))
        pw_page.mouse.down
      end
    end
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
    if page.driver.is_a?(Capybara::Selenium::Driver)
      page.driver.browser.action
        .move_to_location(element.location.x + 50, element.location.y + 10)
        .click_and_hold
        .move_by(0, -element.location.y + 3)
        .move_by(3, 0)
        .perform
    else
      page.driver.with_playwright_page do |pw_page|
        box = element.bounding_box
        playwright_mouse_move(pw_page, box['x'] + 50, box['y'] + 10)
        pw_page.mouse.down
        playwright_mouse_move(pw_page, box['x'] + 50, 13, steps: 5)
        playwright_mouse_move(pw_page, box['x'] + 53, 13)
      end
    end
  end

  # Counts the macro entries of the batch overlay that are geometrically visible,
  # i.e. whose bounding box overlaps the overlay's clipped area.
  #
  # The entries flex-wrap inside a container capped by `max-height` with
  # `overflow: hidden`, so only some of them fall within the visible clipped
  # area - the rest are still rendered in the DOM, just occluded. Capybara's
  # Selenium driver treats such clipped-out elements as not visible, but the
  # Playwright driver's visibility check only walks the CSS
  # display/visibility/opacity chain and does not consider clipping by an
  # ancestor's overflow, so it counts all of them. Computing the count here
  # keeps the assertion meaningful on both drivers.
  #
  # @example
  # wait.until { visible_macro_entry_count == 32 }
  #
  def visible_macro_entry_count
    page.evaluate_script(<<~JS)
      (function() {
        var containerRect = document.querySelector('.batch-overlay-macro .batch-overlay-box-inner').getBoundingClientRect();
        return Array.from(document.querySelectorAll('.batch-overlay-macro-entry')).filter(function(el) {
          var r = el.getBoundingClientRect();
          return r.bottom > containerRect.top && r.top < containerRect.bottom;
        }).length;
      })()
    JS
  end

  # Moves the mouse to a position derived from an element's location on the x-axis,
  # combined with an explicit y-coordinate - e.g. sliding a dragged item down to a
  # fixed position near the bottom of the viewport to reveal a drop target that
  # starts below the fold, regardless of the element's own vertical position.
  #
  # @example
  # slide_mouse_to(circle, x_offset: 20, y_coord: target_y)
  #
  def slide_mouse_to(element, x_offset:, y_coord:)
    if page.driver.is_a?(Capybara::Selenium::Driver)
      page.driver.browser.action.move_to_location(element.native.location.x + x_offset, y_coord).perform
    else
      page.driver.with_playwright_page do |pw_page|
        # The element may still be sliding into place (e.g. a drop target
        #   revealed by a preceding hover/drag step) - #bounding_box also
        #   returns nil while it's not yet visible, so read its settled
        #   position instead of racing the animation.
        box = playwright_fixed_bounding_box(element)
        playwright_mouse_move(pw_page, box['x'] + x_offset, y_coord)
      end
    end
  end

  # Releases the depressed left mouse button at the current mouse location.
  #
  # @example
  # release_mouse
  #
  def release_mouse
    if page.driver.is_a?(Capybara::Selenium::Driver)
      page.driver.browser.action.release.perform
    else
      page.driver.with_playwright_page { |pw_page| pw_page.mouse.up }
    end
    await_empty_ajax_queue
  end

  # Playwright's Mouse#move is absolute while Selenium's move_by is relative -
  # remember the pointer position so relative moves can be reproduced.
  #
  def playwright_mouse_move(pw_page, x_coord, y_coord, steps: 1)
    pw_page.mouse.move(x_coord, y_coord, steps: steps)
    @playwright_mouse_position = { x: x_coord, y: y_coord }
  end

  def playwright_mouse_position
    @playwright_mouse_position ||= { x: 0, y: 0 }
  end

  # Playwright counterpart of Capybara::Node::Element#in_fixed_position:
  # waits until an (animated) element stopped moving and returns its bounding box.
  #
  # Takes a Capybara element (not a native handle): an unrelated app update can
  # replace the underlying DOM node while we're waiting (e.g. a collection
  # controller re-rendering a list item), which permanently detaches a fixed
  # native handle - #bounding_box would then return nil forever instead of
  # settling. Reloading before each read re-resolves the element's original
  # query, picking up whatever node currently matches instead of polling a
  # handle that's gone for good.
  #
  def playwright_fixed_bounding_box(element, checks: 100, wait: 0.2)
    previous = element.native.bounding_box

    (checks + 1).times do
      sleep wait

      current = element.reload.native.bounding_box

      # #bounding_box returns nil while the element is detached/not laid out
      # (e.g. mid-transition). Two nil reads in a row are not "stable" - keep
      # waiting for a real box instead of returning nil to the caller.
      return current if current && previous == current

      previous = current
    end

    raise "Element still moving after #{checks} checks"
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
