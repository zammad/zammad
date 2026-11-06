# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module PlaywrightNative
  module PageAreas
    def page_navigation
      page.get_by_role('navigation', name: 'Navigation')
    end

    def main_content
      page.get_by_role('main')
    end

    def main_sidebar
      page.get_by_role('complementary', name: 'Main sidebar')
    end

    def content_sidebar
      page.get_by_role('complementary', name: 'Content sidebar')
    end

    def flyout(title)
      page.get_by_role('complementary', name: title, exact: true)
    end

    # Notifications share the alert role with the app's other alerts.
    def notification(text)
      page.get_by_role('alert').filter(hasText: text)
    end

    # The body rows of a table, without its header row.
    def table_rows(caption, within: page)
      within.get_by_role('table', name: caption).get_by_role('row').filter(has: page.get_by_role('cell'))
    end
  end
end

RSpec.configure do |config|
  config.include PlaywrightNative::PageAreas, type: :playwright
end
