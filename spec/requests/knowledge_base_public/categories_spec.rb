# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase public categories', type: :request do
  include_context 'basic Knowledge Base'

  before do
    # Skip asset generation.
    allow_any_instance_of(ActionView::Base).to receive(:compute_asset_path).and_return('')
  end

  # The help site renders the same sorting modes the agent interface offers, so a category set to
  #   alphabetical or last update reads the same in both places — per list, the two being stored
  #   apart (`category_sorting_mode` / `answer_sorting_mode`).
  describe 'sorting mode' do
    # Distinctive enough not to collide with anything else in the rendered page.
    def answer_titled(title, **attributes)
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title: "SortingCanary #{title}" }, **attributes)
    end

    def rendered_order(*records)
      get help_category_path(locale_name, category)

      records
        .sort_by { |record| response.body.index(record.translation.title) || Float::INFINITY }
        .map(&:id)
    end

    let(:zulu)  { answer_titled('Zulu') }
    let(:alpha) { answer_titled('Alpha') }

    before do
      zulu
      alpha
    end

    it 'keeps the hand-arranged order in the manual mode' do
      expect(rendered_order(alpha, zulu)).to eq([zulu.id, alpha.id])
    end

    context 'with the alphabetical mode' do
      before { category.update!(category_sorting_mode: 'alphabetical', answer_sorting_mode: 'alphabetical') }

      it 'orders the answers by title' do
        expect(rendered_order(alpha, zulu)).to eq([alpha.id, zulu.id])
      end

      # The desktop view groups a preloaded tree in Ruby while this renders straight from SQL, so
      #   the two only agree about non-ASCII titles as long as both take the order from the
      #   database. Asserting them against each other is what catches a regression there.
      it 'orders non-ASCII titles the same way the desktop view does' do
        %w[Ähre Šalis Zebra].each { |title| answer_titled(title) }

        get help_category_path(locale_name, category)
        public_order = response.body.scan(%r{SortingCanary (?:Ähre|Šalis|Zebra)})

        desktop_order = Service::KnowledgeBase::Answers
          .with_current_user(create(:admin))
          .execute(category:, locale: primary_locale)
          .map { |answer| answer.translation.title }
          .grep(%r{SortingCanary (?:Ähre|Šalis|Zebra)})

        expect(public_order).to eq(desktop_order)
          .and eq(['SortingCanary Ähre', 'SortingCanary Šalis', 'SortingCanary Zebra'])
      end

      it 'orders the subcategories by title' do
        late  = create(:knowledge_base_category, knowledge_base:, parent: category, translations: [build(:knowledge_base_category_translation, title: 'SortingCanary Yankee', kb_locale: primary_locale)])
        early = create(:knowledge_base_category, knowledge_base:, parent: category, translations: [build(:knowledge_base_category_translation, title: 'SortingCanary Bravo', kb_locale: primary_locale)])

        create(:knowledge_base_answer, :published, category: late)
        create(:knowledge_base_answer, :published, category: early)

        expect(rendered_order(early, late)).to eq([early.id, late.id])
      end
    end

    context 'with the last update mode' do
      before { category.update!(answer_sorting_mode: 'last_update') }

      it 'orders by the most recently edited first' do
        travel_to(1.hour.from_now) { zulu.translation.update!(title: 'SortingCanary Zulu, edited') }

        expect(rendered_order(alpha, zulu)).to eq([zulu.id, alpha.id])
      end

      # The internal publication date is never shown here, so it must not order the list either —
      #   an answer internally published long ago but made public just now is new to this audience.
      it 'ignores the internal publication date' do
        [alpha, zulu].each { |answer| answer.translation.update!(edited_at: 5.days.ago) }

        internal_first = answer_titled('Echo', internal_at: 10.days.ago, published_at: 1.minute.ago)
        internal_first.translation.update!(edited_at: 10.days.ago)

        # Dated by its public release a minute ago, not by the internal one ten days back — which
        #   would have put it last.
        expect(rendered_order(alpha, zulu, internal_first).first).to eq(internal_first.id)
      end
    end

    context 'with the subcategories in the last update mode' do
      before { category.update!(category_sorting_mode: 'last_update') }

      def subcategory_titled(title)
        create(:knowledge_base_category, knowledge_base:, parent: category, translations: [build(:knowledge_base_category_translation, title: "SortingCanary #{title}", kb_locale: primary_locale)])
          .tap { |subcategory| create(:knowledge_base_answer, :published, category: subcategory) }
      end

      # Dated explicitly rather than by creation order, so nothing rests on two records made in the
      #   same instant.
      let!(:older) { subcategory_titled('Older').tap { |cat| cat.translation_primary.update!(edited_at: 1.week.ago) } }
      let!(:newer) { subcategory_titled('Newer').tap { |cat| cat.translation_primary.update!(edited_at: 1.hour.ago) } }

      it 'orders the subcategories by the most recently edited first' do
        travel_to(1.hour.from_now) { older.translation_primary.update!(title: 'SortingCanary Older, edited') }

        expect(rendered_order(newer, older)).to eq([older.id, newer.id])
      end

      # A category is dated by the content below it, which is the whole reason it carries an
      #   editorial timestamp of its own rather than being read off `updated_at`.
      it 'counts an edit to an answer filed below a subcategory' do
        travel_to(1.hour.from_now) { older.answers.first.translation.update!(title: 'Answer, edited') }

        expect(rendered_order(newer, older)).to eq([older.id, newer.id])
      end

      # Both of these move `updated_at`, and neither is an edit of anything the help site shows.
      it 'leaves the order alone for a reorder or a sorting-mode switch' do
        travel_to(1.hour.from_now) do
          older.move_to_top
          older.update!(answer_sorting_mode: 'alphabetical')
        end

        expect(rendered_order(newer, older)).to eq([newer.id, older.id])
      end
    end

    # The combination a single mode per category could not express, and the one the help site has to
    #   render as two independent listings on the same page.
    context 'with the two lists of one category in different modes' do
      before { category.update!(category_sorting_mode: 'alphabetical', answer_sorting_mode: 'manual') }

      it 'orders the subcategories by title while the answers keep their hand-arranged order', :aggregate_failures do
        late  = create(:knowledge_base_category, knowledge_base:, parent: category, translations: [build(:knowledge_base_category_translation, title: 'SortingCanary Yankee', kb_locale: primary_locale)])
        early = create(:knowledge_base_category, knowledge_base:, parent: category, translations: [build(:knowledge_base_category_translation, title: 'SortingCanary Bravo', kb_locale: primary_locale)])

        create(:knowledge_base_answer, :published, category: late)
        create(:knowledge_base_answer, :published, category: early)

        expect(rendered_order(early, late)).to eq([early.id, late.id])
        expect(rendered_order(alpha, zulu)).to eq([zulu.id, alpha.id])
      end
    end

    # The top level has no category above it to carry a mode, so the knowledge base itself holds the
    #   one for its root categories — the single listing on the help site sorted by
    #   `knowledge_base.category_sorting_mode`.
    context 'with the top level listing' do
      # Only categories with something to show are listed, so each one gets an answer.
      def root_category_titled(title)
        create(:knowledge_base_category, knowledge_base:, translations: [build(:knowledge_base_category_translation, title: "SortingCanary #{title}", kb_locale: primary_locale)])
          .tap { |root_category| create(:knowledge_base_answer, :published, category: root_category) }
      end

      def rendered_root_order(*records)
        get help_root_path(locale_name)

        records
          .sort_by { |record| response.body.index(record.translation.title) || Float::INFINITY }
          .map(&:id)
      end

      # Created against their alphabetical order, so the hand-arranged order disagrees with it.
      let!(:yankee) { root_category_titled('Yankee') }
      let!(:bravo)  { root_category_titled('Bravo') }

      it 'keeps the hand-arranged order in the manual mode' do
        expect(rendered_root_order(bravo, yankee)).to eq([yankee.id, bravo.id])
      end

      context 'with the alphabetical mode' do
        before { knowledge_base.update!(category_sorting_mode: 'alphabetical') }

        it 'orders the root categories by title' do
          expect(rendered_root_order(bravo, yankee)).to eq([bravo.id, yankee.id])
        end
      end
    end
  end
end
