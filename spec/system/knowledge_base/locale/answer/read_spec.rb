# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Knowledge Base Locale Answer Read', type: :system, authenticated_as: true do
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
end
