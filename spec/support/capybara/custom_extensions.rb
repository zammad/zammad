# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Capybara::Node::Element

  # This is an extension to each node to check if the element
  # is moving or in a fixed position. This is especially helpful
  # for animated elements that cause flanky tests.
  # NOTE: In CI env a special sleep is performed between checks
  # because animations can be slow.
  #
  # @param [Integer] checks the number of performed movement checks
  #
  # @example
  #  find('.clues-close').in_fixed_position.click
  # => waits till clues moved to final position and performs click afterwards
  #
  # @raise [RuntimeError] raised in case the element is
  #   still moving after max number of checks was passed
  #
  # @return [Capybara::Node::Element] the element/node
  def in_fixed_position(checks: 100, wait: 0.2)
    # PLAYWRIGHT PILOT: Playwright::ElementHandle has no #location (Selenium-only),
    #   use its #bounding_box instead to detect settling. Unlike #location it
    #   answers nil while the element is detached or not laid out (e.g. mid
    #   transition), so two nil reads must not count as "stopped moving" - that
    #   would hand the caller a still-moving element.
    playwright = session.driver.is_a?(Capybara::Playwright::Driver)
    position   = -> { playwright ? native.bounding_box : native.location }
    previous   = position.call

    (checks + 1).times do
      sleep wait

      current = position.call

      return self if current && previous == current

      previous = current
    end

    raise "Element still moving after #{checks} checks"
  end
end

module ZammadCapybarActionDelegator
  def select(...)
    super.tap do
      await_empty_ajax_queue
    end
  end

  def unselect(...)
    super.tap do
      await_empty_ajax_queue
    end
  end

  def click(...)
    retry_on_click_intercepted { super }.tap do
      await_empty_ajax_queue
    end
  end

  # Retryable click failures, all of them "the target was not usable yet":
  #   - Selenium: a fading/animating overlay (e.g. a modal mid-transition)
  #     briefly obscured the element.
  #   - Playwright: the target kept moving for its whole actionability wait
  #     ('not stable'), or it was re-rendered from under us (nav menu on chat WS
  #     events, links swapped during boot) and outlasted Capybara's own
  #     synchronize window.
  #
  # Retries are few and cheap on purpose: the stale case has already burned
  #   Capybara's full wait before landing here, so a genuinely gone element
  #   should not be retried many times over.
  RETRYABLE_CLICK_ERRORS = [
    Selenium::WebDriver::Error::ElementClickInterceptedError,
    Capybara::Playwright::Node::StaleReferenceError,
    Playwright::Error,
  ].freeze

  def retry_on_click_intercepted(retries: 2)
    tries = 0
    begin
      yield
    rescue *RETRYABLE_CLICK_ERRORS => e
      # Playwright::Error is the driver's catch-all (TimeoutError and friends
      #   inherit from it), so only its actionability timeout qualifies -
      #   anything else is a real error.
      raise if e.is_a?(Playwright::Error) && e.message.exclude?('not stable')

      tries += 1
      raise if tries > retries

      # Re-resolve the element for the next attempt where there is one; at
      #   session level (click_on and friends) the call re-runs its own lookup.
      reload if respond_to?(:reload)
      sleep 0.3
      retry
    end
  end

  def click_on(...)
    retry_on_click_intercepted { super }.tap do
      await_empty_ajax_queue
    end
  end

  def click_link(...)
    retry_on_click_intercepted { super }.tap do
      await_empty_ajax_queue
    end
  end

  def click_link_or_button(...)
    retry_on_click_intercepted { super }.tap do
      await_empty_ajax_queue
    end
  end

  def click_button(...)
    retry_on_click_intercepted { super }.tap do
      await_empty_ajax_queue
    end
  end

  def select_option(...)
    super.tap do
      await_empty_ajax_queue
    end
  end

  def send_keys(...)
    super.tap do
      await_empty_ajax_queue
    end
  end

  def fill_in(...)
    super.tap do
      await_empty_ajax_queue
    end
  end

  def hot_keys
    mac_platform? ? %i[control alt] : %i[shift control]
  end

  def magic_key
    mac_platform? ? :command : :control
  end

  def mac_platform?
    (ENV['SELENIUM_BROWSER_OS'] || Gem::Platform.local.os).eql? 'darwin'
  end

  def check(...)
    super.tap do
      await_empty_ajax_queue
    end
  end
end

module ZammadCapybarSelectorDelegator
  def find_field(...)
    ZammadCapybaraElementDelegator.new(element: super, context: self)
  end

  def find_button(...)
    ZammadCapybaraElementDelegator.new(element: super, context: self)
  end

  def find_by_id(...)
    ZammadCapybaraElementDelegator.new(element: super, context: self)
  end

  def find_link(...)
    ZammadCapybaraElementDelegator.new(element: super, context: self)
  end

  def find(...)
    ZammadCapybaraElementDelegator.new(element: super, context: self)
  end

  def first(...)
    ZammadCapybaraElementDelegator.new(element: super, context: self)
  end

  def all(...)
    super.map { |element| ZammadCapybaraElementDelegator.new(element: element, context: self) }
  end
end

class ZammadCapybaraSessionDelegator < SimpleDelegator
  extend Forwardable

  def_delegator :@context, :await_empty_ajax_queue
  attr_reader :element

  include ZammadCapybarSelectorDelegator

  def initialize(context:, element:)
    @context = context
    @element = element

    super(element)
  end
end

class ZammadCapybaraElementDelegator < ZammadCapybaraSessionDelegator
  include ZammadCapybarActionDelegator
end

module CapybaraCustomExtensions
  include ZammadCapybarActionDelegator
  include ZammadCapybarSelectorDelegator

  def page(...)
    ZammadCapybaraSessionDelegator.new(element: super, context: self)
  end
end

RSpec.configure do |config|
  config.include CapybaraCustomExtensions, type: :system
end
