# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What the browser and the database have to answer for, and nothing else. The state machine behind
#   the bar — which list is armed, what a picked mode previews, which mutation a Save sends — is
#   covered case by case in
#   app/frontend/apps/desktop/pages/knowledge-base/__tests__/knowledge-base-sorting.spec.ts, and the
#   order each mode produces in spec/models/knowledge_base/{category,answer}_spec.rb and the reorder
#   service specs.
#
# Left to this file: that a saved mode really comes back after a reload, that the automatic orders
#   are the ones the database collation and the editorial timestamps produce, and the pointer drag —
#   which needs client rectangles JSDOM does not have.
RSpec.describe 'Desktop > Knowledge Base > Sorting', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent)       { create(:agent, roles: [Role.find_by(name: 'Agent'), role_editor]) }
  let(:role_editor) { create(:role, permission_names: %w[knowledge_base.editor]) }

  let!(:knowledge_base) { create(:knowledge_base) }
  let(:primary_locale)  { knowledge_base.kb_locales.first }
  let(:locale)          { primary_locale.system_locale.locale }

  # Both modes stated rather than left to the defaults, and written after the create: a top level
  #   category has no answer mode above it to inherit, so its answers start on
  #   KnowledgeBase::DEFAULT_SORTING_MODE — and assigning the column default on create is invisible
  #   to dirty tracking, which is exactly when KnowledgeBase::Category#inherit_sorting_modes takes
  #   over. Every example below then starts from a hand-made order and says for itself when it
  #   wants another mode.
  let!(:category) do
    create(:knowledge_base_category,
           knowledge_base: knowledge_base,
           translations:   [build(:knowledge_base_category_translation, title: 'Arranged category', kb_locale: primary_locale)])
      .tap { |record| record.update!(category_sorting_mode: 'manual', answer_sorting_mode: 'manual') }
  end

  # Titles deliberately at odds with the positions the records are created in: an assertion that
  #   holds under either order proves nothing.
  let!(:zulu_subcategory) do
    create(:knowledge_base_category,
           knowledge_base: knowledge_base,
           parent:         category,
           translations:   [build(:knowledge_base_category_translation, title: 'Zulu subcategory', kb_locale: primary_locale)])
  end

  let!(:alpha_subcategory) do
    create(:knowledge_base_category,
           knowledge_base: knowledge_base,
           parent:         category,
           translations:   [build(:knowledge_base_category_translation, title: 'Alpha subcategory', kb_locale: primary_locale)])
  end

  let!(:zulu_answer) do
    create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Zulu answer' })
  end

  let!(:alpha_answer) do
    create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Alpha answer' })
  end

  let(:category_path) { "/knowledge-base/locale/#{locale}/category/#{category.id}" }

  # The order the page lists content in. A content card is the only link to a category or an answer
  #   that carries a heading — the header's breadcrumb links carry none — so the href is what tells
  #   the two listings apart.
  def listed(kind)
    all("a[href*='/#{kind}/'] h3").map(&:text)
  end

  def expect_listed(kind, titles)
    expect(page).to have_css("a[href*='/#{kind}/'] h3", count: titles.size)

    begin
      wait.until { listed(kind) == titles }
    rescue Selenium::WebDriver::Error::TimeoutError
      raise "Expected the #{kind} listed as #{titles.inspect}, got #{listed(kind).inspect}"
    end
  end

  # The entry lives behind the header's action menu. Scoped to the full header, which the compact
  #   one duplicates off-screen until scrolled into place.
  def arm_sorting
    within '[data-test-id="knowledge-base-header-full"]' do
      click_on 'Additional actions'
    end

    click_on 'Sort content'

    expect(page).to have_css('[role="tablist"][aria-label="Sorting mode"]')
  end

  # The two lists take on a name of their own while they are the one being arranged (see
  #   KnowledgeBaseBrowse.vue), which is also what a screen reader is given on entering them.
  def order_list_label(scope)
    { categories: 'Category order list', answers: 'Answer order list' }.fetch(scope)
  end

  def order_list(scope)
    find("ol[aria-label='#{order_list_label(scope)}']")
  end

  # Puts the keyboard into the list, which nothing but the list itself can take: while the bar is up
  #   it holds no focusable descendant — the cards have lost their links — so the driver refuses to
  #   send keys to it, and the chain of controls standing before it is nothing these examples are
  #   about. The presses themselves then go to the page, i.e. to whatever this focused.
  def focus_order_list(scope)
    page.execute_script(<<~JS)
      document.querySelector("ol[aria-label='#{order_list_label(scope)}']")?.focus();
    JS

    expect(page).to have_css("ol[aria-label='#{order_list_label(scope)}']:focus")
  end

  # Which item the keyboard is on, which the list says rather than the item: the focus stays on the
  #   list element itself, so `aria-activedescendant` naming the item's own DOM id is the only sign
  #   of it (see useKeyboardKeysForDragAndDrop.ts).
  #
  # Asserted through a waiting matcher on the list, not by reading the attribute off the node once:
  #   an arrow key is handled a render later than the press.
  def expect_keyboard_on(scope, title)
    item_id = order_list(scope).find('li', text: title)['id']

    expect(page).to have_css("ol[aria-label='#{order_list_label(scope)}'][aria-activedescendant='#{item_id}']")
  end

  # Row by row through a waiting matcher rather than as one snapshot of `all`, which does not retry.
  #   The cards show their title alone while the bar is up — the counts and the menu step aside — so
  #   the item's own text is the title.
  def expect_arranged(scope, titles)
    titles.each_with_index do |title, index|
      expect(page).to have_css("ol[aria-label='#{order_list_label(scope)}'] > li:nth-child(#{index + 1})", text: title)
    end
  end

  describe 'picking a mode' do
    # One mode per list, so the two are set in one visit and have to come back independently of each
    #   other. The reopened bar is what reads them back: it starts every list on the mode the browsed
    #   node is stored with.
    it 'stores a mode for each list and reopens on it', :aggregate_failures do
      visit category_path

      arm_sorting

      click_on 'Sort alphabetically'

      click_on 'Answers'
      click_on 'Sort by latest updates'

      click_on 'Save'

      wait_for_mutation('knowledgeBaseReorderCategories')
      wait_for_mutation('knowledgeBaseReorderAnswers')

      expect(category.reload).to have_attributes(
        category_sorting_mode: 'alphabetical',
        answer_sorting_mode:   'last_update',
      )

      refresh

      expect_listed(:category, ['Alpha subcategory', 'Zulu subcategory'])

      arm_sorting

      expect(page).to have_css('[role="tab"][aria-selected="true"]', text: 'Sort alphabetically')

      click_on 'Answers'

      expect(page).to have_css('[role="tab"][aria-selected="true"]', text: 'Sort by latest updates')
    end

    # Everything below the bar leads away from a mode or an order that is not saved yet, so while it
    #   is up the cards are no links at all.
    it 'cannot open a category or an answer while the bar is up' do
      visit category_path

      # Ends with the id: `*=` would also match a longer id starting with the same digits.
      expect(page).to have_css("a[href$='/category/#{alpha_subcategory.id}']")

      arm_sorting

      expect(page).to have_no_css("a[href$='/category/#{alpha_subcategory.id}']")

      click_on 'Answers'

      expect(page).to have_no_css("a[href$='/answer/#{alpha_answer.id}']")
    end
  end

  describe 'the automatic modes' do
    # Deliberately not compared in Ruby: it orders by codepoint, PostgreSQL by the database
    #   collation, and the listing is the database's — see KnowledgeBase::Category.sorted_by_mode.
    #   What is asserted here is the locale the titles are taken from, which is the browsed one, with
    #   the same fallback chain the displayed title uses.
    context 'with a second locale' do
      let!(:alternative_locale) do
        create(:knowledge_base_locale, knowledge_base: knowledge_base, system_locale: Locale.find_by(locale: 'lt'))
      end

      before do
        # Reverses the alphabetical order against the primary locale: last there, first here.
        create(:knowledge_base_category_translation, category: zulu_subcategory, kb_locale: alternative_locale, title: 'Aardvark subcategory')

        category.update!(category_sorting_mode: 'alphabetical')
      end

      it 'lists alphabetically by the title shown in the browsed locale' do
        visit category_path

        expect_listed(:category, ['Alpha subcategory', 'Zulu subcategory'])
      end

      # The other subcategory has no translation in this locale, so it is both listed and sorted
      #   under the title it falls back to.
      it 'sorts an untranslated category by the title it falls back to' do
        visit "/knowledge-base/locale/lt/category/#{category.id}"

        expect_listed(:category, ['Aardvark subcategory', 'Alpha subcategory'])
      end
    end

    # `edited_at` of the answer's own translation, moved by an edit and by nothing else. Written
    #   here rather than driven through the answer editor, which has its own specs: what this
    #   asserts is the listing that reads the timestamp back.
    it 'lists the most recently edited answer first' do
      category.update!(answer_sorting_mode: 'last_update')

      visit category_path

      expect_listed(:answer, ['Alpha answer', 'Zulu answer'])

      zulu_answer.translations.first.update!(title: 'Zulu answer, edited')

      refresh

      expect_listed(:answer, ['Zulu answer, edited', 'Alpha answer'])
    end
  end

  describe 'arranging by hand' do
    it 'persists a category dragged into a new place', :aggregate_failures do
      visit category_path

      arm_sorting

      expect_arranged(:categories, ['Zulu subcategory', 'Alpha subcategory'])

      # From the tile itself, which is the whole drag target: the grip the card shows while the bar
      #   is up is decorative (see KnowledgeBaseCategoryCard.vue).
      zulu  = find('li.draggable', text: 'Zulu subcategory')
      alpha = find('li.draggable', text: 'Alpha subcategory')

      # `.to_s` because the drivers disagree on the type: Selenium answers with the string, the
      #   Playwright driver with the native boolean (as `spec/system/manage/sla_spec.rb` does).
      expect(zulu['draggable'].to_s).to eq('true')

      zulu.drag_to(alpha, html5: true)

      expect_arranged(:categories, ['Alpha subcategory', 'Zulu subcategory'])

      click_on 'Save'

      wait_for_mutation('knowledgeBaseReorderCategories')

      expect(category.children.reorder(position: :asc).pluck(:id)).to eq([alpha_subcategory.id, zulu_subcategory.id])

      refresh

      expect_listed(:category, ['Alpha subcategory', 'Zulu subcategory'])
    end

    it 'persists an answer dragged into a new place', :aggregate_failures do
      visit category_path

      arm_sorting
      click_on 'Answers'

      expect_arranged(:answers, ['Zulu answer', 'Alpha answer'])

      # From the row rather than its handle this time: the whole card stays the drag target it has
      #   always been, and the handle narrows nothing.
      zulu  = find('li.draggable', text: 'Zulu answer')
      alpha = find('li.draggable', text: 'Alpha answer')

      zulu.drag_to(alpha, html5: true)

      expect_arranged(:answers, ['Alpha answer', 'Zulu answer'])

      click_on 'Save'

      wait_for_mutation('knowledgeBaseReorderAnswers')

      expect(category.answers.reorder(position: :asc).pluck(:id)).to eq([alpha_answer.id, zulu_answer.id])

      refresh

      expect_listed(:answer, ['Alpha answer', 'Zulu answer'])
    end

    # The keyboard path, end to end in a real browser: the grid itself is what takes the focus, so
    #   `aria-activedescendant` is the only thing that says which tile the arrow keys are on, and
    #   the live region is the only thing that says what a press did. Which order the presses stage
    #   is covered in the frontend spec above — asserted here is that a real browser's focus and
    #   live region carry them, and that Save writes the result down.
    #
    # Sideways, not down: the tiles are laid out as a grid, and two of them sit in one row — where
    #   down and up wrap within the column and land back on the tile they started from (see
    #   useKeyboardKeysForDragAndDrop).
    it 'persists an order made by keyboard, announcing what it did', :aggregate_failures do
      visit category_path

      arm_sorting

      # Entering the grid is what starts the keyboard on the first tile, which this Space then holds
      #   for a swap.
      focus_order_list(:categories)

      send_keys(:space)

      expect_keyboard_on(:categories, 'Zulu subcategory')
      expect(page).to have_css('#announcer-message', text: 'Zulu subcategory selected.', visible: :all)

      # `:right`, not `:arrow_right`: Selenium knows both spellings, the Playwright driver only
      #   this one (`Capybara::Playwright::Node::KEYS`).
      send_keys(:right)

      # The arrow key moved the grid's own idea of where the keyboard is, so the next press acts on
      #   the tile it landed on.
      expect_keyboard_on(:categories, 'Alpha subcategory')

      send_keys(:space)

      expect(page).to have_css('#announcer-message', text: 'Swapped Zulu subcategory with Alpha subcategory. Zulu subcategory moved to position 2.', visible: :all)

      expect_arranged(:categories, ['Alpha subcategory', 'Zulu subcategory'])

      click_on 'Save'

      wait_for_mutation('knowledgeBaseReorderCategories')

      expect(category.children.reorder(position: :asc).pluck(:id)).to eq([alpha_subcategory.id, zulu_subcategory.id])

      refresh

      expect_listed(:category, ['Alpha subcategory', 'Zulu subcategory'])
    end

    # Where the next category and the next answer land, which is the one thing the manual mode
    #   cannot derive from the content itself. The records are created behind the page rather than
    #   through the add flyout and the answer editor, both of which have their own specs — what is
    #   asserted here is the position the listing then shows them in.
    it 'lists content created later at the bottom', :aggregate_failures do
      visit category_path

      expect_listed(:category, ['Zulu subcategory', 'Alpha subcategory'])

      create(:knowledge_base_category,
             knowledge_base: knowledge_base,
             parent:         category,
             translations:   [build(:knowledge_base_category_translation, title: 'Added subcategory', kb_locale: primary_locale)])

      create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Added answer' })

      refresh

      expect_listed(:category, ['Zulu subcategory', 'Alpha subcategory', 'Added subcategory'])
      expect_listed(:answer, ['Zulu answer', 'Alpha answer', 'Added answer'])
    end
  end

  # The root lists categories and holds no answers, and its mode lives on the knowledge base itself
  #   — so arranging the top level says nothing about how any category arranges its own content.
  describe 'the knowledge base root' do
    before do
      create(:knowledge_base_category,
             knowledge_base: knowledge_base,
             translations:   [build(:knowledge_base_category_translation, title: 'Another category', kb_locale: primary_locale)])
    end

    it 'sorts its top level independently of a category', :aggregate_failures do
      visit "/knowledge-base/locale/#{locale}"

      arm_sorting

      # No answers here, so there is nothing to pick between.
      expect(page).to have_no_css('[role="tablist"][aria-label="Content type"]')

      click_on 'Sort alphabetically'
      click_on 'Save'

      wait_for_mutation('knowledgeBaseReorderRootCategories')

      expect(knowledge_base.reload.category_sorting_mode).to eq('alphabetical')

      # The point of the example: arranging the top level says nothing about how any category
      #   arranges its own content.
      expect(category.reload).to have_attributes(category_sorting_mode: 'manual', answer_sorting_mode: 'manual')

      expect_listed(:category, ['Another category', 'Arranged category'])
    end
  end

  context 'without editor access' do
    let(:agent)       { create(:agent, roles: [Role.find_by(name: 'Agent'), role_reader]) }
    let(:role_reader) { create(:role, permission_names: %w[knowledge_base.reader]) }

    # A category a reader can see at all has to hold something published: an empty one is not
    #   listed for them, and this example wants both listings on screen.
    before do
      create(:knowledge_base_answer, :published, category: zulu_subcategory)
      create(:knowledge_base_answer, :published, category: alpha_subcategory)
    end

    # A reader has no action the header menu could hold, so there is no menu at all — and nothing
    #   the bar would be reachable through.
    it 'offers no sorting and no drag grips', :aggregate_failures do
      visit category_path

      expect(page).to have_text('Zulu subcategory').and have_text('Zulu answer')

      expect(page).to have_no_button('Additional actions')
      expect(page).to have_no_css('.icon-grip-vertical')
      expect(page).to have_no_css('li.draggable')
    end
  end
end
