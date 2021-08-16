# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

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
            expect(page).to have_css('a', text: published_answer_tag_name)
          end
        end
      end

      it 'opens search on clicking' do
        within :active_content do
          find('.knowledge-base-article-tags--container a', text: published_answer_tag_name).click
        end

        search_bar = find '#global-search'

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
end
