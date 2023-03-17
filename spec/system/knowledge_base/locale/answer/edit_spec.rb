# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Locale Answer Edit', type: :system do
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

      find('a[data-action="link"]').click

      within('.popover-content') do
        find('input').fill_in with: input
        find('[type=submit]').click
      end
    end

    it 'allows mailto links' do
      open_editor_and_add_link 'mailto:test@example.com'

      expect(page).to have_link(href: 'mailto:test@example.com')
    end

    it 'allows link with a protocol' do
      open_editor_and_add_link 'protocol://example.org'

      expect(page).to have_link(href: 'protocol://example.org')
    end

    it 'allows relative link' do
      open_editor_and_add_link '/path'

      expect(page).to have_link(href: '/path')
    end

    it 'allows non-protocol URL and prepends default protocol' do
      open_editor_and_add_link 'example.com'

      expect(page).to have_link(href: 'http://example.com')
    end
  end

  context 'embedded video' do

    it 'has adding functionality' do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{primary_locale.system_locale.locale}/answer/#{published_answer.id}/edit"

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

  context 'tags' do
    before do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/answer/#{published_answer_with_tag.id}/edit"
    end

    let(:new_tag_name) { 'capybara_kb_tag' }

    it 'adds a new tag' do
      within :active_content do
        click '.js-newTagLabel'

        elem = find('.js-newTagInput')
        elem.fill_in with: new_tag_name
        elem.send_keys :return

        wait.until_exists { published_answer_with_tag.reload.tag_list.include? new_tag_name }
        expect(page).to have_link(new_tag_name, href: false, class: ['js-tag'])
      end
    end

    it 'triggers autocomplete after one character' do
      within :active_content do
        click '.js-newTagLabel'

        elem = find('.js-newTagInput')
        elem.fill_in with: 'e'
        expect(page).to have_css('ul.ui-autocomplete > li.ui-menu-item', minimum: 1)
      end
    end

    it 'shows an existing tag' do
      within :active_content do
        expect(page).to have_link(published_answer_tag_name, href: false, class: ['js-tag'])
      end
    end

    it 'deletes a tag' do
      within :active_content do
        find('.list-item', text: published_answer_tag_name)
          .find('.js-delete').click

        expect(page).to have_no_link(published_answer_tag_name, href: false, class: ['js-tag'])
        wait.until_exists { published_answer_with_tag.reload.tag_list.exclude? published_answer_tag_name }
      end
    end
  end

  context 'deleted by another user' do
    before do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{primary_locale.system_locale.locale}/answer/#{published_answer.id}/edit"
    end

    it 'shows not available', performs_jobs: true do
      find(:active_content, text: published_answer.translations.first.title)

      perform_enqueued_jobs do
        ActiveRecord::Base.transaction do
          published_answer.destroy
        end
      end

      within :active_content do
        expect(page).to have_text('The page is not available anymore')
      end
    end
  end

  context 'updated by another user' do
    before do
      ensure_websocket do
        visit "#knowledge_base/#{knowledge_base.id}/locale/#{primary_locale.system_locale.locale}/answer/#{published_answer.id}/edit"
      end

      travel 1.minute
    end

    it 'shows new content', performs_jobs: true do
      find(:active_content, text: published_answer.translations.first.title)

      accept_prompt do
        perform_enqueued_jobs do
          Transaction.execute do
            published_answer.translations.first.update! title: 'new title'
          end
        end
      end

      within :active_content do
        expect(page).to have_text('new title')
      end
    end
  end
end
