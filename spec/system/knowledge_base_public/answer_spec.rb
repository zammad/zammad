# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    context 'self-hosted video content' do
      before do
        Setting.set('kb_self_hosted_video_servers', [{ 'host' => 'video.example.com', 'name' => 'Example' }])
        published_answer_with_self_hosted_video
      end

      it 'shows the embedded player for a whitelisted media server' do
        visit help_answer_path(primary_locale.system_locale.locale, category, published_answer_with_self_hosted_video)

        iframe = find('iframe')
        expect(iframe['src']).to eq('https://video.example.com/videos/embed/uuid-1')
      end
    end

    context 'image content' do
      before do
        published_answer_with_image
      end

      it 'opens inline images in a preview overlay' do
        visit help_answer_path(primary_locale.system_locale.locale, category, published_answer_with_image)

        find('.article-content img').click

        within '.kb-image-preview' do
          expect(page).to have_css('img.kb-image-preview-image')
          expect(page).to have_link('Download')
          click_on 'Close'
        end

        expect(page).to have_no_css('.kb-image-preview')
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
        published_answer.translations.first.touch(:edited_at)
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

      it 'replaced by editorial update time if later than publishing time' do
        translation = published_answer.translations.first
        translation.content.update! body: 'updated body'

        open_answer published_answer

        within '.article .article-meta' do
          expect(page).to have_time_tag published_answer.translations.first.edited_at
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

  context 'attachments' do
    before do
      visit help_answer_path(locale_name, category, published_answer)
    end

    # Making sure it shows the shorthand.
    # This way we can get away without translating Byte(s).
    it 'shows an associated attachment' do
      expect(page)
        .to have_css('.attachment-size', text: '12 B')
        .and(have_no_css('.attachment-size', text: 'Byte'))
    end
  end

  context 'previous and next answers link' do
    before do
      published_answer
      published_answer_in_subcategory
      published_answer_in_other_category
    end

    it 'has previous and next links' do
      visit help_answer_path(locale_name, subcategory, published_answer_in_subcategory)

      expect(page).to have_css('h1', text: published_answer_in_subcategory.translations.first.title)
      expect(page).to have_no_css('.article-nav-adjacent-previous')

      click '.article-nav-adjacent-next a'

      expect(page).to have_css('h1', text: published_answer.translations.first.title)

      expect(page).to have_text(published_answer_in_subcategory.translations.first.title)
      expect(page).to have_text(published_answer_in_other_category.translations.first.title)

      click '.article-nav-adjacent-next a'

      expect(page).to have_css('h1', text: published_answer_in_other_category.translations.first.title)

      expect(page).to have_text(published_answer.translations.first.title)
      expect(page).to have_no_css('.article-nav-adjacent-next')

      click '.article-nav-adjacent-previous a'
      click '.article-nav-adjacent-previous a'

      expect(page).to have_css('h1', text: published_answer_in_subcategory.translations.first.title)
    end
  end

  def open_answer(answer, locale: primary_locale.system_locale.locale)
    visit help_answer_path(locale, answer.category, answer)
  end
end
