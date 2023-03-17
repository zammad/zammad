# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base answer', type: :system do
  include_context 'basic Knowledge Base'

  context 'when not authenticated', authenticated_as: false do
    context 'video content' do
      before do
        published_answer_with_video
      end

      it 'shows video player' do
        visit help_answer_path(primary_locale.system_locale.locale, category, published_answer_with_video)

        iframe = find('iframe')
        expect(iframe['src']).to start_with('https://www.youtube.com/embed/')
      end
    end

    context 'publishing time' do
      it 'shown for published item' do
        open_answer published_answer
        expect(page).to have_css('.article-meta time')
      end

      it 'shown for published item scheduled to be archived' do
        published_answer.update! archived_at: 1.day.from_now

        open_answer published_answer
        expect(page).to have_css('.article-meta time')
      end
    end
  end

  context 'when logged in as editor' do
    before do # simulate translation being created before publishing
      visit '/'

      travel_to published_answer.published_at - 1.week do
        published_answer.translations.first.touch
      end
    end

    context 'publishing time' do
      it 'shown for published item' do
        open_answer published_answer

        within '.article .article-meta' do
          expect(page).to have_time_tag published_answer.published_at
        end
      end

      it 'shown for published item scheduled to be archived' do
        published_answer.update! archived_at: 1.day.from_now

        open_answer published_answer

        within '.article .article-meta' do
          expect(page).to have_time_tag published_answer.published_at
        end
      end

      it 'not shown for item scheduled to be published' do
        draft_answer.update! published_at: 1.day.from_now

        open_answer draft_answer

        within '.article' do
          expect(page).not_to have_time_tag
        end
      end

      it 'not shown for draft item' do
        open_answer draft_answer

        within '.article' do
          expect(page).not_to have_time_tag
        end
      end

      it 'not shown for internal item' do
        open_answer internal_answer

        within '.article' do
          expect(page).not_to have_time_tag
        end
      end

      it 'not shown for archived item' do
        open_answer archived_answer

        within '.article' do
          expect(page).not_to have_time_tag
        end
      end

      it 'replaced by update time if later than publishing time' do
        translation = published_answer.translations.first
        translation.content.update! body: 'updated body'

        open_answer published_answer

        within '.article .article-meta' do
          expect(page).to have_time_tag published_answer.translations.first.updated_at
        end
      end
    end
  end

  context 'tags' do
    before do
      visit help_answer_path(locale_name, category, published_answer_with_tag)
    end

    it 'shows an associated tag' do
      expect(page).to have_css('.tags a', text: published_answer_tag_name)
    end

    it 'links to tag page' do
      click '.tags a'

      expect(current_url).to end_with help_tag_path(locale_name, published_answer_tag_name)
    end
  end

  def open_answer(answer, locale: primary_locale.system_locale.locale)
    visit help_answer_path(locale, answer.category, answer)
  end
end
