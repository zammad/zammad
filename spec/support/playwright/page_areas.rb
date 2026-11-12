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

    # The ticket's floating toolbar offers an icon-only copy while the articles are not scrolled
    #   to the end, the article list's button carries the text.
    def add_internal_note_button
      main_content.get_by_role('button', name: 'Add internal note', exact: true).filter(hasText: 'Add internal note')
    end

    # An article of a ticket with its actions. Its body is an article of its own inside.
    def ticket_article(text)
      main_content.get_by_role('article').filter(hasText: text).filter(has: page.get_by_role('button', name: 'Action menu button'))
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
