# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Locale Answer Read', authenticated_as: true, type: :system do
  include_context 'basic Knowledge Base'

  describe 'tags' do
    context 'when answer has tags' do
      before do
        visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/answer/#{published_answer_with_tag.id}"
      end

      it 'has tags container' do
        within :active_content do
          expect(page).to have_css('.knowledge-base-article-tags--container')
        end
      end

      it 'shows tag' do
        within :active_content do
          within '.knowledge-base-article-tags--container' do
            expect(page).to have_link(published_answer_tag_name)
          end
        end
      end

      it 'opens search on clicking' do
        within :active_content do
          find('.knowledge-base-article-tags--container a', text: published_answer_tag_name).click
        end

        search_bar = find_by_id 'global-search'

        expect(search_bar.value).to eq "tags:#{published_answer_tag_name}"
      end
    end

    context 'when answer has no tags' do
      before do
        visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/answer/#{published_answer.id}"
      end

      it 'has no tags container' do
        within :active_content do
          expect(page).to have_no_css('.knowledge-base-article-tags--container')
        end
      end
    end
  end

  context 'deleted by another user' do
    before do
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/answer/#{published_answer.id}"
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
        visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/answer/#{published_answer.id}"
      end

      travel 1.minute
    end

    it 'shows new content', performs_jobs: true do
      find(:active_content, text: published_answer.translations.first.title)

      perform_enqueued_jobs do
        Transaction.execute do
          published_answer.translations.first.update! title: 'new title'
        end
      end

      within :active_content do
        expect(page).to have_text('new title')
      end
    end
  end

  context 'when switching between locales' do
    let(:long_locale_name)   { 'sr-cyrl-rs' }
    let(:long_system_locale) { Locale.find_by(locale: long_locale_name) }
    let(:long_kb_locale)     { create(:knowledge_base_locale, knowledge_base: knowledge_base, system_locale: long_system_locale) }

    let(:short_locale_name)   { 'lt' }
    let(:short_system_locale) { Locale.find_by(locale: short_locale_name) }
    let(:short_kb_locale)     { create(:knowledge_base_locale, knowledge_base: knowledge_base, system_locale: short_system_locale) }

    before do
      long_kb_locale && short_kb_locale
    end

    it 'switches from long locale back to main locale' do
      open_page long_locale_name
      select_locale 'English'

      within '.knowledge-base-article' do
        expect(page).to have_text(published_answer.translations.first.title)
      end
    end

    it 'switches from short locale back to main locale' do
      open_page short_locale_name
      select_locale 'English'

      within '.knowledge-base-article' do
        expect(page).to have_text(published_answer.translations.first.title)
      end
    end

    it 'switches from main locale to another locale' do
      another_translation = create(:knowledge_base_answer_translation, kb_locale: short_kb_locale, answer: published_answer)

      open_page locale_name
      select_locale 'Lietuvių'

      within '.knowledge-base-article' do
        expect(page).to have_text(another_translation.title)
      end
    end

    it 'switches to invalid locale and back' do
      open_page('lol')

      in_modal do
        click_on 'Open in primary locale'
      end

      within '.knowledge-base-article' do
        expect(page).to have_text(published_answer.translations.first.title)
      end
    end

    def open_page(locale_name)
      visit "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/answer/#{published_answer.id}"
    end

    def select_locale(text)
      within '.js-pickedLanguage + .dropdown' do
        click '.icon-arrow-down'
        click 'li a', text: text
      end
    end
  end
end
