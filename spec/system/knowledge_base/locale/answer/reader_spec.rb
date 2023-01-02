# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Locale Answer Reader', time_zone: 'Europe/London', type: :system do
  include_context 'basic Knowledge Base'

  context 'when logged in as editor' do
    before do # simulate translation being created before publishing
      date = published_answer.published_at - 1.week
      published_answer.translations.first.update! created_at: date, updated_at: date
    end

    context 'state' do
      it 'shown as "Draft" for draft' do
        open_answer draft_answer

        within :active_content do
          expect(page).to have_css('.knowledge-base-article-meta', text: 'Draft')
        end
      end

      it 'shown as "Internal" for internal' do
        open_answer internal_answer

        within :active_content do
          expect(page).to have_css('.knowledge-base-article-meta', text: 'Internal')
        end
      end

      it 'shown as "Published" for published' do
        open_answer published_answer

        within :active_content do
          expect(page).to have_css('.knowledge-base-article-meta', text: 'Published')
        end
      end

      it 'shown as "Archived" for archived' do
        open_answer archived_answer

        within :active_content do
          expect(page).to have_css('.knowledge-base-article-meta', text: 'Archived')
        end
      end
    end

    context 'time' do
      it 'shown for internal' do
        travel_to internal_answer.internal_at - 1.week do
          internal_answer.translations.first.touch
        end

        open_answer internal_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).to have_time_tag(internal_answer.internal_at)
        end
      end

      it 'shown for published' do
        travel_to published_answer.published_at do
          published_answer.translations.first.touch
        end

        open_answer published_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).to have_time_tag published_answer.published_at
        end
      end

      it 'internal publishing time shown if published is present too' do
        published_answer.update! internal_at: published_answer.published_at - 1.day

        travel_to published_answer.published_at - 2.days do
          published_answer.translations.first.touch
        end

        open_answer published_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).to have_time_tag published_answer.internal_at
        end
      end

      it 'not shown for draft' do
        open_answer draft_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).not_to have_time_tag
        end
      end

      it 'not shown for archived' do
        open_answer archived_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).not_to have_time_tag
        end
      end

      it 'replaced by update time if later than publishing time' do
        translation = published_answer.translations.first
        translation.content.update! body: 'updated body'

        open_answer published_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).to have_time_tag published_answer.translations.first.updated_at
        end
      end
    end

    context 'user', current_user_id: -> { user.id } do
      let(:user) { create(:admin) }

      it 'shown for internal' do
        open_answer internal_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).to have_text user.fullname
        end
      end

      it 'shown for published' do
        open_answer published_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).to have_text user.fullname
        end
      end

      it 'not shown for draft' do
        open_answer draft_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).to have_no_text user.fullname
        end
      end

      it 'not shown for archived' do
        open_answer archived_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).to have_no_text user.fullname
        end
      end

      it 'shows translation updater rather than publisher' do
        published_answer.update! published_by_id: 1

        open_answer published_answer

        within :active_content, '.knowledge-base-article-meta' do
          expect(page).to have_text user.fullname
        end
      end
    end
  end

  context 'when logged in as reader', authenticated: -> { visitor }, current_user_id: -> { editor.id } do
    let(:editor) { create(:admin, firstname: 'Editor') }
    let(:visitor) { create(:agent) }

    it 'state not shown' do
      open_answer published_answer

      within :active_content, '.knowledge-base-article-meta' do
        expect(page).to have_no_text('published')
      end
    end

    it 'time shown' do
      travel_to published_answer.published_at - 1.week do
        published_answer.translations.first.touch
      end

      open_answer published_answer

      within :active_content, '.knowledge-base-article-meta' do
        expect(page).to have_time_tag(published_answer.published_at)
      end
    end

    it 'user shown' do
      open_answer published_answer

      within :active_content, '.knowledge-base-article-meta' do
        expect(page).to have_text editor.fullname
      end
    end
  end

  def open_answer(answer, locale: primary_locale)
    visit "knowledge_base/#{answer.category.knowledge_base.id}/locale/#{locale.system_locale.locale}/answer/#{answer.id}"
  end
end
