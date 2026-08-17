# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# https://github.com/zammad/zammad/issues/266
RSpec.describe 'Admin Panel > Knowledge Base > Theme', type: :system do
  include_context 'basic Knowledge Base'

  context 'header link color' do
    before do
      knowledge_base
      visit '/#manage/knowledge_base'
    end

    it 'shows color' do
      elem = find('#color_header_link input')

      expect(elem.value).to eq knowledge_base.color_header_link
    end

    it 'saves new color' do
      find('#color_header_link input').fill_in with: '#ccc'
      find('#color_header_link button').click

      await_empty_ajax_queue

      expect(knowledge_base.reload.color_header_link).to eq '#ccc'
    end
  end

  # https://github.com/zammad/zammad/issues/6301
  context 'icon set' do
    def switch_iconset_to(name)
      within 'form', text: 'Icon Set' do
        find(".js-set[data-family='#{name}']").click
        click_on 'Submit'
      end
    end

    context 'with existing categories' do
      before do
        category
        visit '/#manage/knowledge_base'
      end

      it 'resets the category icons after confirmation' do
        switch_iconset_to 'material'

        in_modal do
          click_on 'Yes'
        end

        await_empty_ajax_queue

        expect(knowledge_base.reload.iconset).to eq 'material'
        expect(category.reload.category_icon).to eq 'e94d'
      end

      it 'applies a submit which leaves the icon set alone without asking for confirmation' do
        icon = category.category_icon

        within 'form', text: 'Icon Set' do
          click_on 'Submit'
        end

        await_empty_ajax_queue

        expect(page).to have_no_css('.modal')
        expect(knowledge_base.reload.iconset).to eq 'FontAwesome'
        expect(category.reload.category_icon).to eq icon
      end

      it 'keeps the icon set and the category icons when the change is canceled' do
        icon = category.category_icon

        switch_iconset_to 'material'

        in_modal do
          click_on 'Cancel'
        end

        await_empty_ajax_queue

        expect(knowledge_base.reload.iconset).to eq 'FontAwesome'
        expect(category.reload.category_icon).to eq icon

        within 'form', text: 'Icon Set' do
          expect(page).to have_css(".js-set[data-family='FontAwesome'].is-active")
          expect(page).to have_no_css(".js-set[data-family='material'].is-active")
        end
      end
    end

    # The knowledge base asset is cached until its own `updated_at` changes, so categories added
    # afterwards must not go unnoticed here (see KnowledgeBase::Category#invalidate_knowledge_base_asset_cache).
    context 'with categories added after the knowledge base was last changed' do
      before do
        knowledge_base
        visit '/#manage/knowledge_base'
        category
        refresh
      end

      it 'asks for confirmation' do
        switch_iconset_to 'material'

        in_modal do
          click_on 'Yes'
        end

        await_empty_ajax_queue

        expect(category.reload.category_icon).to eq 'e94d'
      end
    end

    context 'without any categories' do
      before do
        knowledge_base
        visit '/#manage/knowledge_base'
      end

      it 'applies the change without asking for confirmation' do
        switch_iconset_to 'material'

        await_empty_ajax_queue

        expect(knowledge_base.reload.iconset).to eq 'material'
        expect(page).to have_no_css('.modal')
      end
    end
  end
end
