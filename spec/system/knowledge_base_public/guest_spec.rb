# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Public Knowledge Base for guest', authenticated_as: false, type: :system do
  include_context 'basic Knowledge Base'

  before do
    published_answer && draft_answer && internal_answer
  end

  context 'homepage' do
    before { visit help_no_locale_path }

    it('is redirected to primary locale') { expect(page).to have_current_path help_root_path(primary_locale.system_locale.locale) }

    it { expect(page).not_to have_breadcrumb }
    it { expect(page).not_to have_editor_bar }

    it 'shows category' do
      within '.main' do
        expect(page).to have_selector(:link_containing, published_answer.category.translation.title)
      end
    end

    it 'does not show answer' do
      within '.main' do
        expect(page).to have_no_selector(:link_containing, published_answer.translation.title)
      end
    end
  end

  context 'category' do
    before { visit help_category_path(primary_locale.system_locale.locale, category) }

    it { expect(page).to have_breadcrumb }

    it 'shows published answer' do
      within '.main' do
        expect(page).to have_selector(:link_containing, published_answer.translation.title)
      end
    end

    it 'does not show draft answer' do
      within '.main' do
        expect(page).to have_no_selector(:link_containing, draft_answer.translation.title)
      end
    end

    it 'does not show internal answer' do
      within '.main' do
        expect(page).to have_no_selector(:link_containing, internal_answer.translation.title)
      end
    end

    context 'breadcrumb' do
      it { expect(page).to have_breadcrumb.with(2).items }
      it { expect(page).to have_breadcrumb_item(knowledge_base.translation.title).at_index(0) }
      it { expect(page).to have_breadcrumb_item(category.translation.title).at_index(1) }
    end

    context 'when looking at translated subcategory' do
      let(:translated_title) { Faker::Lorem.sentence }

      before do
        create(:knowledge_base_translation,
               knowledge_base:, kb_locale: alternative_locale)

        create(:knowledge_base_category_translation,
               category: category, title: translated_title, kb_locale: alternative_locale)

        create(:knowledge_base_category_translation,
               category: subcategory, kb_locale: alternative_locale)

        create(:knowledge_base_answer_translation,
               answer: published_answer_in_subcategory, kb_locale: alternative_locale)

        visit help_category_path(alternative_locale.system_locale.locale, subcategory)
      end

      it 'shows translated parent category in breadcrumb' do
        expect(page).to have_breadcrumb_item(translated_title).at_index(1)
      end
    end

    # The reporter's path: a category translated to the primary locale only, whose subcategory and
    #   answer are translated to the second one as well.
    #   See https://github.com/zammad/zammad/issues/6368
    context 'when looking at a translated subcategory below an untranslated category' do
      let(:translated_subcategory_title) { Faker::Lorem.sentence }

      before do
        create(:knowledge_base_translation,
               knowledge_base:, kb_locale: alternative_locale)

        create(:knowledge_base_category_translation,
               category: subcategory, title: translated_subcategory_title, kb_locale: alternative_locale)

        create(:knowledge_base_answer_translation,
               answer: published_answer_in_subcategory, kb_locale: alternative_locale)

        visit help_root_path(alternative_locale.system_locale.locale)
      end

      it 'reaches the subcategory through the category shown under its primary title', :aggregate_failures do
        click_on category.translation_primary.title

        expect(page).to have_breadcrumb_item(category.translation_primary.title).at_index(1)

        click_on translated_subcategory_title

        expect(page).to have_css('h1', text: translated_subcategory_title)
        expect(page).to have_breadcrumb_item(category.translation_primary.title).at_index(1)
      end
    end
  end

  context 'answer' do
    before { visit help_answer_path(primary_locale.system_locale.locale, category, published_answer) }

    context 'breadcrumb' do
      it { expect(page).to have_breadcrumb.with(3).items }
      it { expect(page).to have_breadcrumb_item(knowledge_base.translation.title).at_index(0) }
      it { expect(page).to have_breadcrumb_item(category.translation.title).at_index(1) }
      it { expect(page).to have_breadcrumb_item(published_answer.translation.title).at_index(2) }
    end
  end

  context 'preview token' do
    context 'when token is valid' do
      let(:token) { Token.renew_token! 'KnowledgeBasePreview', create(:admin).id }

      it 'loads draft answer' do
        visit help_answer_path(primary_locale.system_locale.locale, category, draft_answer, preview_token: token)

        within '.main--article' do
          expect(page).to have_text(draft_answer.translations.first.title)
        end
      end
    end

    context 'when token user does not have access' do
      let(:token) { Token.renew_token! 'KnowledgeBasePreview', create(:customer).id }

      it 'loads draft answer' do
        visit help_answer_path(primary_locale.system_locale.locale, category, draft_answer, preview_token: token)

        expect(page).to have_no_text(draft_answer.translations.first.title)
      end
    end
  end

  context 'wrong locale' do
    before { visit help_root_path(alternative_locale.system_locale.locale) }

    it { expect(page).to have_language_banner }

    context 'switch to correct locale after clicking on language banner' do
      before do
        within '.language-banner' do
          click_on 'activate'
        end
      end

      it { expect(page).not_to have_language_banner }
    end
  end

  context 'offer in another locale' do
    before do
      create(:knowledge_base_translation, kb_locale: alternative_locale)
      visit help_answer_path(alternative_locale.system_locale.locale, category, published_answer)
    end

    it { expect(page).to have_text(published_answer.translation_primary.title) }
    it { expect(page).to have_text('only available in these languages') }
    it { expect(page).to have_no_selector('h1', text: published_answer.translation_primary.title) }

    context 'follow primary locale' do
      before { click_on published_answer.translation_primary.title }

      it { expect(page).to have_css('h1', text: published_answer.translation_primary.title) }
    end
  end

  context '404' do
    before { visit help_answer_path(primary_locale.system_locale.locale, category, 12_345) }

    it { expect(page).to have_text('Page not found') }
  end
end
