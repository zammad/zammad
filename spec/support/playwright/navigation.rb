# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module PlaywrightNative
  module Navigation
    def open_desktop(route)
      page.goto("/desktop#{route}")
      wait_for_test_flag('applicationLoaded.loaded', skip_clearing: true)
    end

    def open_mobile(route)
      page.goto("/mobile#{route}")
      wait_for_test_flag('applicationLoaded.loaded', skip_clearing: true)
    end

    # A ticket of the desktop view, with its form ready for input.
    def open_desktop_ticket(ticket)
      open_desktop("/tickets/#{ticket.id}")
      wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
    end

    # The reloaded app has to load again, like after open_desktop and open_mobile.
    def reload_page
      page.reload
      wait_for_test_flag('applicationLoaded.loaded', skip_clearing: true)
    end

    # Another tab of the same browser, it shares the cookies and the storage of `page`.
    def open_tab
      browser_context.new_page
    end

    # The helpers act on `page`, so a block of them acts on another tab this way.
    def on_tab(tab)
      previous = page
      @page = tab
      yield
    ensure
      @page = previous
    end
  end
end

RSpec.configure do |config|
  config.include PlaywrightNative::Navigation, type: :playwright
end
