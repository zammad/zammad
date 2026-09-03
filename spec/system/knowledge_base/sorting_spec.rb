# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The legacy interface renders the sorting modes the desktop view sets, and offers rearranging by
#   hand only while the mode reads a hand-made order back.
#
# The order itself is worked out client side (App.KnowledgeBaseSorting), which
#   public/assets/tests/qunit/knowledge_base_sorting.js covers case by case. What is asserted here is
#   that the browsed page actually goes through it, and what the editor is shown when it cannot
#   rearrange.
RSpec.describe 'Knowledge Base sorting', authenticated_as: :user, type: :system do
  include_context 'basic Knowledge Base'

  let(:user) { create(:admin) }

  # Titles deliberately at odds with the positions: an assertion that holds under either order
  #   proves nothing.
  let(:zulu)  { create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'Zulu answer' }) }
  let(:alpha) { create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'Alpha answer' }) }

  let(:category_url) { "#knowledge_base/#{knowledge_base.id}/locale/#{locale_name}/category/#{category.id}" }
  let(:edit_url)     { "#{category_url}/edit" }

  before do
    zulu
    alpha
  end

  def listed_answers
    all('.js-readerListContainer .section .title').map(&:text).grep(%r{answer\z})
  end

  describe 'browsing a category' do
    it 'keeps the hand-arranged order in the manual mode' do
      visit category_url

      expect(listed_answers).to eq(['Zulu answer', 'Alpha answer'])
    end

    context 'with the answers sorted alphabetically' do
      before { category.update!(answer_sorting_mode: 'alphabetical') }

      it 'lists them by title' do
        visit category_url

        expect(listed_answers).to eq(['Alpha answer', 'Zulu answer'])
      end
    end
  end

  # Both lists of a category are ordered from the same modal the sidebar has always opened, which now
  #   also picks the mode. What the modes themselves order is App.KnowledgeBaseSorting's, covered
  #   case by case in the QUnit file above; what is asserted here is the modal around it.
  describe 'the editor sidebar' do
    def open_answers_reorder
      visit edit_url

      expect(page).to have_css('.sidebar-block .js-reorder', count: 2)
      find_all('.sidebar-block .js-reorder').last.click

      find('.modal')
    end

    def listed_rows(modal)
      modal.all('tr.item').map { |row| row['data-id'].to_i }
    end

    # The Answers block of the sidebar - the list the modal was opened from, and the one thing on
    #   this page that shows its order.
    #
    # Row by row through a waiting matcher rather than as one snapshot of `all`, which does not
    #   retry: the block re-renders a moment after the save (App.KnowledgeBaseSidebar#rerender is
    #   delayed), so a snapshot races it and reads the order from before.
    def expect_sidebar_answers(titles)
      block = all('.sidebar-block').last

      titles.each_with_index do |title, index|
        expect(block).to have_css(".kb-sidebar-block-content li:nth-child(#{index + 1})", text: title)
      end
    end

    it 'offers rearranging both lists of a category' do
      visit edit_url

      expect(page).to have_css('.sidebar-block .js-reorder', count: 2)
    end

    it 'offers the three modes, with the stored one active', :aggregate_failures do
      modal = open_answers_reorder

      expect(modal.all('.js-sortingMode').map(&:text))
        .to eq(['Sort alphabetically', 'Sort by drag & drop', 'Sort by latest updates'])
      expect(modal.find('.js-sortingMode.active')).to have_text('Sort by drag & drop')
    end

    context 'with the answers listed alphabetically' do
      before { category.update!(answer_sorting_mode: 'alphabetical') }

      it 'opens on the stored mode, showing the list as it is on screen', :aggregate_failures do
        modal = open_answers_reorder

        expect(modal.find('.js-sortingMode.active')).to have_text('Sort alphabetically')
        expect(listed_rows(modal)).to eq([alpha.id, zulu.id])
      end
    end

    # Picking a mode previews the order it is about to store. An automatic one cannot be dragged,
    #   because the order it stores is not the rows' to decide.
    it 'previews an automatic mode without offering to drag it', :aggregate_failures do
      modal = open_answers_reorder
      expect(modal).to have_css('td.table-draggable')

      modal.find('.js-sortingMode', text: 'Sort alphabetically').click

      expect(listed_rows(modal)).to eq([alpha.id, zulu.id])
      expect(modal).to have_no_css('td.table-draggable')
    end

    it 'stores the picked mode and lists the category in it afterwards', :aggregate_failures do
      modal = open_answers_reorder
      modal.find('.js-sortingMode', text: 'Sort alphabetically').click
      modal.find('.js-submit').click

      expect(page).to have_no_css('.modal')
      expect(category.reload.answer_sorting_mode).to eq('alphabetical')

      # In place, off the save: nothing in the list changed, only the mode on the category above it,
      #   so the lists that read that mode have to be told (see App.ControllerReorderModal#save).
      expect_sidebar_answers ['Alpha answer', 'Zulu answer']

      visit category_url
      expect(listed_answers).to eq(['Alpha answer', 'Zulu answer'])
    end

    # Arming drag & drop means saying what the order is, so it starts from the rows on screen rather
    #   than from the positions that happen to be stored - the same order the save then sends. Its
    #   counterpart on the other stack is `pendingChanges` in useKnowledgeBaseSorting.ts.
    context 'with the answers listed alphabetically and rearranged from there' do
      before { category.update!(answer_sorting_mode: 'alphabetical') }

      it 'starts the drag & drop order from the rows on screen', :aggregate_failures do
        modal = open_answers_reorder
        modal.find('.js-sortingMode', text: 'Sort by drag & drop').click

        # The alphabetical order it was showing, not the hand-made [zulu, alpha] behind it.
        expect(listed_rows(modal)).to eq([alpha.id, zulu.id])
        expect(modal).to have_css('td.table-draggable')

        modal.find('.js-submit').click

        expect(page).to have_no_css('.modal')
        expect(category.reload.answer_sorting_mode).to eq('manual')
        expect_sidebar_answers ['Alpha answer', 'Zulu answer']

        # Stored as positions, so it survives as the hand-made order from here on.
        expect(category.answers.reorder(position: :asc).pluck(:id)).to eq([alpha.id, zulu.id])
      end
    end
  end
end
