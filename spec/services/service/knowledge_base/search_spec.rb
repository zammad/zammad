# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Search do
  include_context 'basic Knowledge Base'

  let(:user) { create(:admin) }

  # A term of its own per example group: searchindex_model_reload reindexes from the database but
  #   leaves the documents of rolled back records behind, and Elasticsearch answers with only the
  #   requested number of hits.
  let(:search_term) { 'ocarina' }

  let(:matching_answer) do
    create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Ocarina tuning' })
  end

  let(:subcategory_answer) do
    create(:knowledge_base_answer, :published, category: subcategory, translation_attributes: { title: 'Ocarina cleaning' })
  end

  let(:other_category_answer) do
    create(:knowledge_base_answer, :published, category: other_category, translation_attributes: { title: 'Ocarina storage' })
  end

  let(:matching_category) do
    create(:knowledge_base_category, knowledge_base: knowledge_base, parent: category).tap do |elem|
      elem.translations.first.update!(title: 'Ocarina department')
    end
  end

  # Title does not match, body does - so its body preview must come from the match rather than
  #   from the excerpt fallback.
  let(:body_only_answer) do
    create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Woodwind notes' }).tap do |elem|
      elem.translations.first.content.update!(body: 'Hold the ocarina with both hands.')
    end
  end

  def search_output(query = search_term, scope: nil)
    described_class
      .with_current_user(user)
      .execute(query: query, knowledge_base: knowledge_base, scope: scope, locale: primary_locale)
  end

  def search(query = search_term, scope: nil)
    search_output(query, scope: scope).results
  end

  def visibility_of(category)
    search_output.category_visibility[category.id]
  end

  def result_for(answer)
    search.find { |result| result.item == answer }
  end

  def highlighted(segments)
    segments.select(&:highlight).map(&:text)
  end

  # The mode the quicksearch group asks for: answers alone, and none of the enrichment the search
  #   page's result list renders. Covered against both backends, because a hit means something
  #   different in each (Elasticsearch narrows to the browsed locale, the SQL fallback does not).
  def quick_search_output(query = search_term, limit: described_class::MAX_RESULTS)
    described_class
      .with_current_user(user)
      .execute(
        query:          query,
        knowledge_base: knowledge_base,
        locale:         primary_locale,
        indexes:        [KnowledgeBase::Answer::Translation.name],
        limit:          limit,
        enriched:       false,
      )
  end

  def quick_search(query = search_term, limit: described_class::MAX_RESULTS)
    quick_search_output(query, limit: limit).results
  end

  shared_examples 'an answers-only, unenriched search' do
    it 'still finds answers' do
      expect(quick_search.map(&:item)).to include(matching_answer)
    end

    it 'returns answers alone, never a category' do
      expect(quick_search.map(&:item)).to all(be_a(KnowledgeBase::Answer))
    end

    # The searchable unit, and what Gql::Types::SearchResult::ItemType exposes for this model - so
    #   the quicksearch group is a list of these rather than of their answers.
    it 'carries the hit translation next to the answer' do
      result = quick_search.find { |elem| elem.item == matching_answer }

      expect(result.translation).to eq(matching_answer.translations.first)
    end

    it 'builds no title preview' do
      expect(quick_search.map(&:title_preview)).to all(be_empty)
    end

    it 'builds no body preview' do
      expect(quick_search.map(&:body_preview)).to all(be_empty)
    end

    # The preview being empty does not prove the body was never fetched: reading it loads the
    #   translation's content row and runs the whole HTML body through html2text. That is why the
    #   fallback is passed to #preview as a block rather than as an argument.
    it 'never loads the answer bodies' do
      expect(quick_search.map { |result| result.translation.association(:content).loaded? }).to all(be(false))
    end

    it 'builds no category path' do
      expect(quick_search.map(&:category_path)).to all(be_empty)
    end

    it 'hands out no batched category data' do
      output = quick_search_output

      expect([output.category_translations, output.category_visibility]).to all(be_empty)
    end

    # The two costs the mode exists to avoid, and the reason it exists at all: quicksearch fires on
    #   every debounced keystroke. Pinned on the calls rather than only on the empty output, because
    #   an output can be empty while the work was still done.
    it 'does not ask the backend for highlights' do
      allow(SearchKnowledgeBaseBackend).to receive(:new).and_call_original

      quick_search

      expect(SearchKnowledgeBaseBackend).to have_received(:new).with(hash_including(highlight_enabled: false))
    end

    it 'never loads the category tree' do
      allow(knowledge_base).to receive(:categories).and_call_original

      quick_search

      expect(knowledge_base).not_to have_received(:categories)
    end

    it 'honours a limit below the default cap' do
      expect(quick_search(limit: 1).size).to eq(1)
    end

    it 'returns nothing for a blank query' do
      expect(quick_search('')).to be_empty
    end
  end

  before do
    matching_answer
    subcategory_answer
    other_category_answer
    matching_category
    body_only_answer
  end

  context 'with Elasticsearch', searchindex: true do
    before do
      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    end

    it 'returns nothing for a blank query, so entering the page searches for nothing' do
      expect(search('')).to be_empty
    end

    it 'finds answers and categories alike' do
      expect(search.map(&:item)).to include(matching_answer, matching_category)
    end

    it 'never returns the knowledge base node itself' do
      expect(search.map { |result| result.item.class }).to all(be_in([KnowledgeBase::Answer, KnowledgeBase::Category]))
    end

    it 'marks the matched run of the title' do
      expect(highlighted(result_for(matching_answer).title_preview)).to eq(['Ocarina'])
    end

    it 'leaves the unmatched runs of the title unmarked' do
      expect(result_for(matching_answer).title_preview.map(&:text).join).to eq('Ocarina tuning')
    end

    it 'marks the match inside the body' do
      expect(highlighted(result_for(body_only_answer).body_preview)).to eq(['ocarina'])
    end

    # The index holds the texts HTML-escaped for the legacy consumers, which render the fragments as
    #   markup; the segments are plain text, so `&amp;` must come back as `&` — and `&nbsp;`, which
    #   the indexer emits for a non-breaking space, as that space.
    context 'with HTML special characters in the title' do
      let(:ampersand_answer) do
        create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Ocarina & order' })
      end

      let(:nbsp_answer) do
        create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: "Ocarina\u00A0<3" })
      end

      before do
        ampersand_answer
        nbsp_answer
        searchindex_model_reload([KnowledgeBase::Answer::Translation])
      end

      it 'previews an ampersand unescaped' do
        expect(result_for(ampersand_answer).title_preview.map(&:text).join).to eq('Ocarina & order')
      end

      it 'previews a non-breaking space and an angle bracket unescaped' do
        expect(result_for(nbsp_answer).title_preview.map(&:text).join).to eq("Ocarina\u00A0<3")
      end
    end

    it 'still previews the body when only the title matched' do
      expect(result_for(matching_answer).body_preview.map(&:text).join).to be_present
    end

    it 'leaves a category without a body preview' do
      expect(result_for(matching_category).body_preview).to be_empty
    end

    it 'reports the category path of an answer, root first' do
      expect(result_for(subcategory_answer).category_path).to eq([category, subcategory])
    end

    it 'reports where a category sits, not the category itself' do
      expect(result_for(matching_category).category_path).to eq([category])
    end

    # CategoryType#visibility renders the status icon of a result from this. It is batched here
    #   because the fallback, KnowledgeBase::Category#content_visibility, walks the subtree with a
    #   recursive query once per publication state — for every category on the page.
    describe 'category visibility' do
      it 'reads a category hit without content as draft' do
        expect(visibility_of(matching_category)).to eq(:draft)
      end

      it 'reports the publication state of the content in the category itself' do
        create(:knowledge_base_answer, :internal, category: matching_category)

        expect(visibility_of(matching_category)).to eq(:internal)
      end

      it 'covers the whole subtree, not the category alone' do
        child = create(:knowledge_base_category, knowledge_base: knowledge_base, parent: matching_category)
        create(:knowledge_base_answer, :published, category: child)

        expect(visibility_of(matching_category)).to eq(:published)
      end

      it 'reports the highest state when the subtree mixes them' do
        create(:knowledge_base_answer, :archived, category: matching_category)
        create(:knowledge_base_answer, :internal, category: matching_category)

        expect(visibility_of(matching_category)).to eq(:internal)
      end

      # Same rule as the browse grid, which derives it from the same
      #   Service::KnowledgeBase::Concerns::WalksCategoryTree: content the browsed locale has no
      #   translation for does not count.
      it 'ignores content that is not translated to the browsed locale' do
        create(:knowledge_base_answer, :published, category:               matching_category,
                                                   translation_attributes: { kb_locale: alternative_locale })

        expect(visibility_of(matching_category)).to eq(:draft)
      end
    end

    context 'when scoped to a category' do
      it 'includes answers of the category and its subcategories' do
        expect(search(scope: category).map(&:item)).to include(matching_answer, subcategory_answer)
      end

      it 'excludes answers of a sibling subtree' do
        expect(search(scope: category).map(&:item)).not_to include(other_category_answer)
      end
    end

    context 'when the indexed record is gone' do
      before { matching_answer.destroy! }

      it 'skips the stale hit instead of failing the whole search' do
        expect(search.map(&:item)).to include(subcategory_answer).and(not_include(matching_answer))
      end
    end

    # Granular permissions make KnowledgeBase.access_for_user :granular for anyone with a flat
    #   editor/reader permission, but this user has neither - #flavor has to fall back to :public
    #   for them regardless, or they would be filtered through grants they were never given.
    context 'with granular permissions in effect, for a user without any knowledge base permission' do
      # Not the :agent factory - its default Agent role grants knowledge_base.reader (see
      #   db/seeds/permissions.rb), which is exactly the flat permission this example excludes.
      let(:user) { create(:agent, roles: [create(:role, permission_names: 'ticket.agent')]) }

      before do
        other_role = create(:role, permission_names: 'knowledge_base.editor')
        KnowledgeBase::PermissionsUpdate.new(other_category).update!(other_role => 'editor')
      end

      it 'takes the public path' do
        expect(KnowledgeBase.access_for_user(user)).to eq(:public)
      end

      it 'still finds published answers outside the granted category' do
        expect(search.map(&:item)).to include(matching_answer)
      end
    end

    it_behaves_like 'an answers-only, unenriched search'
  end

  context 'without Elasticsearch' do
    before { Setting.set('es_url', nil) }

    it 'still finds answers' do
      expect(search.map(&:item)).to include(matching_answer)
    end

    it 'returns the plain title as a single unmarked segment' do
      expect(result_for(matching_answer).title_preview.map { |segment| [segment.text, segment.highlight] })
        .to eq([['Ocarina tuning', false]])
    end

    it 'falls back to the body excerpt, unmarked' do
      preview = result_for(body_only_answer).body_preview

      expect(preview.map(&:highlight)).to eq([false])
    end

    it_behaves_like 'an answers-only, unenriched search'
  end
end
