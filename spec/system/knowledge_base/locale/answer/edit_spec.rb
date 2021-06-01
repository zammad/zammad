# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Locale Answer Edit', type: :system, authenticated_as: true do
  include_context 'basic Knowledge Base'

  before do
    published_answer && draft_answer && internal_answer
  end

  it 'wraps long texts' do
    long_string = '3KKFA9DAWE9VJYNNnpYRRtMwfa168O1yvpD2t9QXsfb3cppGV6KZ12q0UUJIy5r4Exfk18GnWPR0A3SoDsjxIHz1Gcu4aCEVzenilSOu4gAfxnB6k3mSBUOGIfdgChEBYhcHGgiCmV2EoXu4gG7GAJxKJhM2d4NUiL5RZttGtMXYYFr2Jsg7MV7xXGcygnsLMYqnwzOJxBK0vH3fzhdIZd6YrqR3fggaY0RyKtVigOBZ2SETC8s238Z9eDL4gfUW'

    visit "#knowledge_base/#{knowledge_base.id}/locale/#{primary_locale.system_locale.locale}/answer/#{draft_answer.id}/edit"

    within(:active_content) do
      find('.richtext-content').send_keys long_string

      expect(page).to have_css('.js-submit') { |elem| !elem.obscured? }
      expect(page).to have_css('.page-header-title') { |elem| !elem.obscured? }
    end
  end

  context 'add weblink' do
    def open_editor_and_add_link(input)
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{primary_locale.system_locale.locale}/answer/#{draft_answer.id}/edit"

      sleep 3 # wait for popover killer to pass

      find('a[data-action="link"]').click

      within('.popover-content') do
        find('input').fill_in with: input
        find('[type=submit]').click
      end
    end

    it 'allows mailto links' do
      open_editor_and_add_link 'mailto:test@example.com'

      expect(page).to have_selector('a[href="mailto:test@example.com"]')
    end

    it 'allows link with a protocol' do
      open_editor_and_add_link 'protocol://example.org'

      expect(page).to have_selector('a[href="protocol://example.org"]')
    end

    it 'allows relative link' do
      open_editor_and_add_link '/path'

      expect(page).to have_selector('a[href="/path"]')
    end

    it 'allows non-protocol URL and prepends default protocol' do
      open_editor_and_add_link 'example.com'

      expect(page).to have_selector('a[href="http://example.com"]')
    end
  end

  context 'embedded video' do

    it 'has adding functionality' do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{primary_locale.system_locale.locale}/answer/#{published_answer.id}/edit"

      sleep 3 # wait for popover killer to pass

      find('a[data-action="embed_video"]').click

      within('.popover-content') do
        find('input').fill_in with: 'https://www.youtube.com/watch?v=vTTzwJsHpU8'
        find('[type=submit]').click
      end

      within('.richtext-content') do
        expect(page).to have_text('( widget: video, provider: youtube, id: vTTzwJsHpU8 )')
      end
    end

    it 'loads stored' do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{primary_locale.system_locale.locale}/answer/#{published_answer_with_video.id}"

      iframe = find('iframe')
      expect(iframe['src']).to start_with('https://www.youtube.com/embed/')
    end
  end
end
