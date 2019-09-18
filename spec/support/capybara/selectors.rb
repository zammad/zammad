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

Capybara.add_selector(:macro) do
  css { |id| %(.js-submitDropdown > ul > li[data-id="#{id}"]) }
end

Capybara.add_selector(:macro_batch) do
  css { |id| %(.batch-overlay-macro-entry[data-id='#{id}']) }
end

Capybara.add_selector(:table_row) do
  css { |id| %(tr[data-id='#{id}']) }
end

Capybara.add_selector(:link_containing) do
  xpath { |text| ".//a//*[text()[contains(.,\"#{text}\")]]" }
end

# Knowledge Base
Capybara.add_selector(:knowledge_base_editor_bar) do
  css { '.topbar' }
end

Capybara.add_selector(:knowledge_base_language_banner) do
  css { '.language-banner' }
end

# don't use "knowledge_base" prefix because breadcrumbs
# could be available in other contexts (in the future)
Capybara.add_selector(:breadcrumb) do
  css { '.breadcrumbs .breadcrumb span' }
end
