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

  # The language picker offers every locale the knowledge base is translated to, so each of them
  #   has to lead somewhere — and content translated to a locale has to be reachable there, whether
  #   or not the category above it is.
  #   See https://github.com/zammad/zammad/issues/6368
  describe 'browsing a locale the category above the content is not translated to' do
    let(:alternative_locale_name) { alternative_locale.system_locale.locale }

    # Fixed titles rather than the factory's, to be found in the page verbatim.
    let(:category) do
      create(:knowledge_base_category, knowledge_base:, translations: [build(:knowledge_base_category_translation, title: 'Primary Only Category', kb_locale: primary_locale)])
    end

    before { create(:knowledge_base_translation, kb_locale: alternative_locale) }

    shared_examples 'a category shown under its primary title' do
      it 'lists the category on the start page under its primary title, linked in the browsed locale', :aggregate_failures do
        get help_root_path(alternative_locale_name)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Primary Only Category')
        expect(response.body).to include(help_category_path(alternative_locale_name, category.translation_primary))
      end

      it 'shows the category under its primary title' do
        get help_category_path(alternative_locale_name, category)

        expect(response.body).to include('<h1>', 'Primary Only Category')
      end

      it 'offers the browsed locale in the language picker of the category' do
        get help_category_path(alternative_locale_name, category)

        expect(response.body).to include(%(hreflang="#{alternative_locale_name}"))
      end
    end

    context 'when a published answer in the category is translated to the browsed locale' do
      before { create(:knowledge_base_answer_translation, answer: published_answer, kb_locale: alternative_locale, title: 'Translated Answer') }

      it_behaves_like 'a category shown under its primary title'

      it 'lists the translated answer in the category' do
        get help_category_path(alternative_locale_name, category)

        expect(response.body).to include('Translated Answer')
      end

      # The page offering the answer in other languages lists its titles too, so what tells the two
      #   apart is its error layout.
      it 'serves the translated answer, rather than offering it in other languages', :aggregate_failures do
        get help_answer_path(alternative_locale_name, category, published_answer)

        expect(response.body).to include('Translated Answer')
        expect(response.body).not_to include('main--error')
      end
    end

    context 'when a subcategory holds a published answer translated to the browsed locale' do
      before do
        create(:knowledge_base_category_translation, category: subcategory, kb_locale: alternative_locale, title: 'Translated Subcategory')
        create(:knowledge_base_answer_translation, answer: published_answer_in_subcategory, kb_locale: alternative_locale)
      end

      it_behaves_like 'a category shown under its primary title'

      it 'lists the translated subcategory in the category' do
        get help_category_path(alternative_locale_name, category)

        expect(response.body).to include('Translated Subcategory')
      end

      it 'shows the category under its primary title in the breadcrumb of the subcategory' do
        get help_category_path(alternative_locale_name, subcategory)

        expect(response.body).to include('class="breadcrumb"', 'Primary Only Category')
      end
    end

    context 'when nothing below the category is translated to the browsed locale' do
      before { published_answer }

      # The empty state is asserted by its markup: its copy is rendered in the browsed locale.
      it 'answers the start page with its empty state instead of not found', :aggregate_failures do
        get help_root_path(alternative_locale_name)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('class="sections-empty"')
        expect(response.body).not_to include('Primary Only Category')
      end

      it 'keeps the category itself unreachable' do
        get help_category_path(alternative_locale_name, category)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when only an unpublished answer below the category is translated to the browsed locale' do
      before { create(:knowledge_base_answer_translation, answer: draft_answer, kb_locale: alternative_locale) }

      it 'leaves the category off the start page', :aggregate_failures do
        get help_root_path(alternative_locale_name)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('Primary Only Category')
      end
    end

    it 'still answers not found for a locale the knowledge base is not configured for' do
      get help_root_path('de-de')

      expect(response).to have_http_status(:not_found)
    end

    # Rather than the whole site again under a made-up address, which the content check alone
    #   would serve.
    it 'answers not found for a locale that does not exist at all', :aggregate_failures do
      published_answer

      get help_root_path('xx-yy')
      expect(response).to have_http_status(:not_found)

      get help_category_path('xx-yy', category)
      expect(response).to have_http_status(:not_found)

      get help_answer_path('xx-yy', category, published_answer)
      expect(response).to have_http_status(:not_found)
    end
  end

  # The knowledge base itself follows the rule its categories do: a configured locale it is not
  #   translated to is served once it holds published content translated to it, under the fallback
  #   title — the language picker on that content offers the locale, so the root has to answer there.
  describe 'browsing a configured locale the knowledge base itself is not translated to' do
    let(:alternative_locale_name) { alternative_locale.system_locale.locale }
    let(:primary_title)           { CGI.escapeHTML(knowledge_base.translation_primary.title) }

    before { alternative_locale }

    context 'when it holds a published answer translated to that locale' do
      before do
        create(:knowledge_base_category_translation, category:, kb_locale: alternative_locale, title: 'Translated Category')
        create(:knowledge_base_answer_translation, answer: published_answer, kb_locale: alternative_locale)
      end

      it 'serves the start page under the primary title, listing the translated category', :aggregate_failures do
        get help_root_path(alternative_locale_name)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(primary_title, 'Translated Category')
      end

      it 'offers the locale in the language picker' do
        get help_root_path(alternative_locale_name)

        expect(response.body).to include(%(hreflang="#{alternative_locale_name}"))
      end

      it 'serves the category page', :aggregate_failures do
        get help_category_path(alternative_locale_name, category)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('<h1>', 'Translated Category')
      end
    end

    context 'when nothing is translated to that locale' do
      before { published_answer }

      it 'answers not found' do
        get help_root_path(alternative_locale_name)

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # The line telling the visitor to add content is an instruction only an editor can follow, and the
  #   empty start page is what a guest now lands on for a locale nothing is translated to yet.
  describe 'the empty state of a listing' do
    it 'tells a guest that there is no content, and nothing more', :aggregate_failures do
      get help_root_path(locale_name)

      expect(response.body).to include('No content to show')
      expect(response.body).not_to include('Please add categories and/or answers')
    end

    it 'tells an editor to add content' do
      authenticated_as(create(:admin), via: :browser)

      get help_root_path(locale_name)

      expect(response.body).to include('Please add categories and/or answers')
    end
  end
end
