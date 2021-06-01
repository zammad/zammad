# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# This file defines custom Capybara selectors for DRYed specs.

Capybara.add_selector(:href) do
  css { |href| %(a[href="#{href}"]) }
end

Capybara.add_selector(:active_content) do
  css { |content_class| ['.content.active', content_class].compact.join(' ') }
end

Capybara.add_selector(:active_ticket_article) do
  css { |article| ['.content.active', "#article-#{article.id}" ].compact.join(' ') }
end

Capybara.add_selector(:manage) do
  css { 'a[href="#manage"]' }
end

Capybara.add_selector(:clues_close) do
  css { '.js-modal--clue .js-close' }
end

Capybara.add_selector(:richtext) do
  css { |name| "div[data-name=#{name || 'body'}]" }
end

Capybara.add_selector(:text_module) do
  css { |id| %(.shortcut > ul > li[data-id="#{id}"]) }
end

Capybara.add_selector(:macro) do
  css { |id| %(.js-submitDropdown > ul > li[data-id="#{id}"]) }
end

Capybara.add_selector(:macro_batch) do
  css { |id| %(.batch-overlay-macro-entry[data-id='#{id}'] .batch-overlay-macro-entry-name) }
end

Capybara.add_selector(:table_row) do
  css { |id| %(tr[data-id='#{id}']) }
end

Capybara.add_selector(:link_containing) do
  xpath { |text| ".//a//*[text()[contains(.,\"#{text}\")]]" }
end

Capybara.add_selector(:task_active) do
  css { '.tasks .task.is-active' }
end

Capybara.add_selector(:task_with) do
  css { |task_key| ".tasks .task[data-key='#{task_key}']" }
end
