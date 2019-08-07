# This file defines custom Capybara selectors for DRYed specs.

Capybara.add_selector(:href) do
  css { |href| %(a[href="#{href}"]) }
end

Capybara.add_selector(:active_content) do
  css { |content_class| ['.content.active', content_class].compact.join(' ') }
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
