# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe SearchKnowledgeBaseBackend do
  include_context 'basic Knowledge Base'

  let(:instance) { described_class.new options.merge(user: user) }
  let(:user)     { create(:admin) }

  let(:options) do
    {
      knowledge_base: knowledge_base,
      locale:         primary_locale,
      scope:          nil
    }
  end

  # The search returns KnowledgeBase::Answer::Translation ids, not answer ids. Comparing against
  #   the answer id only works while the two sequences happen to line up, which is true in a
  #   freshly seeded database and stops being true as soon as they drift apart.
  def translation_id(answer)
    answer.translations.first!.id
  end

  def handle_elasticsearch(enabled)
    if enabled
      searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
    else
      Setting.set('es_url', nil)
    end
  end

  context 'with ES', searchindex: true do
    describe '#search' do
      context 'when highlight enabled' do
        let(:options) do
          {
            knowledge_base:    knowledge_base,
            locale:            primary_locale,
            scope:             nil,
            highlight_enabled: true
          }
        end

        before do
          published_answer
          searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
        end

        # https://github.com/zammad/zammad/issues/3070
        it 'lists item with an attachment' do
          expect(instance.search('Hello World')).to be_present
        end

        context 'with big attachment' do
          before do
            url = "#{Setting.get('es_url')}/_all/_settings?preserve_existing=true"
            SearchIndexBackend.make_request_and_validate(url, data: { index: { 'highlight.max_analyzed_offset': 1000 } }, method: :put)
          end

          # An index setting outlives the database transaction: left in place, it makes Elasticsearch refuse to
          #   highlight any longer text in a later example and fail the whole search.
          after do
            url = "#{Setting.get('es_url')}/_all/_settings"
            SearchIndexBackend.make_request_and_validate(url, data: { index: { 'highlight.max_analyzed_offset': nil } }, method: :put)
          end

          let(:attachment) { fixture_file_upload('spec/fixtures/files/upload/lipsum.pdf') }

          let :published_answer do
            create(:knowledge_base_answer, :published, :with_attachment, attachment:, category: category)
          end

          it 'lists item with an attachment' do
            expect(instance.search('Suspendisse')).to be_present
          end
        end
      end
    end

    describe '#search without drafts and archived answers' do
      let(:options) do
        {
          knowledge_base:              knowledge_base,
          locale:                      primary_locale,
          scope:                       nil,
          flavor:                      :agent,
          index:                       'KnowledgeBase::Answer::Translation',
          include_drafts_and_archived: false,
        }
      end

      let(:answers) do
        %i[draft internal published archived].index_with do |state|
          create(:knowledge_base_answer, state, category: category, translation_attributes: { title: "Kalimba #{state}" })
        end
      end

      before do
        answers
        searchindex_model_reload([KnowledgeBase::Answer::Translation])
      end

      it 'leaves them out in Elasticsearch already, for an editor too', :aggregate_failures do
        published = answers.values_at(:internal, :published).map { |answer| translation_id(answer) }

        expect(instance.raw_results('kalimba').pluck(:id)).to match_array(published)
        expect(instance.search('kalimba').pluck(:id)).to match_array(published)
      end

      it 'finds an answer published since the index took it, as the database says' do
        answers[:draft].update!(internal_at: 1.minute.ago)

        expect(instance.search('kalimba').pluck(:id)).to include(translation_id(answers[:draft]))
      end

      it 'refuses a search beyond answers, whose documents the answers would filter out' do
        expect { described_class.new(options.except(:index)) }.to raise_error(ArgumentError)
      end
    end

    describe '#search with shortcut queries' do
      let(:ai_generated_answer) { create(:knowledge_base_answer, :published, :with_tag, tag_names: ['ai-generated'], category: category) }

      let(:recently_created) { travel_to(2.days.ago) { create(:knowledge_base_answer, :published, category: category) } }

      let(:old_answer) { travel_to(30.days.ago) { create(:knowledge_base_answer, :published, category: category) } }

      let(:recently_updated) do
        travel_to(30.days.ago) { create(:knowledge_base_answer, :published, category: category) }.tap do |answer|
          travel_to(1.day.ago) { answer.translations.first.touch(:edited_at) }
        end
      end

      before do
        draft_answer
        published_answer
        ai_generated_answer
        recently_created
        old_answer
        recently_updated
        searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
      end

      describe 'publication_state:draft' do
        let(:query)  { 'publication_state:draft' }
        let(:result) { instance.search(query) }
        let(:ids)    { result.pluck(:id).map(&:to_i) }

        it 'finds drafts' do
          expect(ids).to include(translation_id(draft_answer))
        end

        it 'excludes published answers' do
          expect(ids).not_to include(translation_id(published_answer))
        end
      end

      describe 'tags:ai-generated' do
        let(:query)  { 'tags:ai-generated' }
        let(:result) { instance.search(query) }
        let(:ids)    { result.pluck(:id).map(&:to_i) }

        it 'finds ai-generated answers' do
          expect(ids).to include(translation_id(ai_generated_answer))
        end

        it 'excludes untagged answers' do
          expect(ids).not_to include(translation_id(published_answer))
        end
      end

      describe 'created_at:>now-14d' do
        let(:query)  { 'created_at:>now-14d' }
        let(:result) { instance.search(query) }
        let(:ids)    { result.pluck(:id).map(&:to_i) }

        it 'finds recently created answers' do
          expect(ids).to include(translation_id(recently_created))
        end

        it 'excludes old answers' do
          expect(ids).not_to include(translation_id(old_answer))
        end
      end

      describe 'edited_at:>now-3d' do
        let(:query)  { 'edited_at:>now-3d' }
        let(:result) { instance.search(query) }
        let(:ids)    { result.pluck(:id).map(&:to_i) }

        it 'finds recently updated answers' do
          expect(ids).to include(translation_id(recently_updated))
        end

        it 'excludes old answers' do
          expect(ids).not_to include(translation_id(old_answer))
        end
      end
    end

    describe '#search relevance' do
      let(:options) do
        {
          knowledge_base: knowledge_base,
          locale:         primary_locale,
          scope:          nil,
          flavor:         :agent,
        }
      end

      let(:search_term) { 'xylophone' }

      let(:matching_category) do
        create(:knowledge_base_category, knowledge_base: knowledge_base).tap do |elem|
          elem.translations.first.update!(title: 'Xylophone department')
        end
      end

      let(:title_match) do
        create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Xylophone maintenance' })
      end

      let(:tag_match) do
        create(:knowledge_base_answer, :published, :with_tag, tag_names: [search_term], category: category, translation_attributes: { title: 'Percussion upkeep' })
      end

      # Repeats the term often enough that its raw term frequency beats a title that mentions it
      #   once. Without the boost this outranks #title_match, so the ordering example below fails
      #   if #options_apply_boost stops doing its job - which a single mention would not prove,
      #   because BM25's field length norm already favours the short title field on its own.
      let(:body_match) do
        create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Completely unrelated heading' }).tap do |elem|
          elem.translations.first.content.update!(body: (['xylophone'] * 40).join(' '))
        end
      end

      let(:result) { instance.search(search_term) }

      before do
        matching_category
        title_match
        tag_match
        body_match
        searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
      end

      it 'returns one merged ranking, ordered by descending score' do
        scores = result.pluck(:score)

        expect(scores).to eq(scores.sort.reverse)
      end

      it 'interleaves categories and answers instead of grouping them by type' do
        types = result.pluck(:type)

        # Grouping by type - which is what #filter_results used to do - puts every answer before
        #   every category, so a category ahead of the last answer can only come from a merged
        #   ranking.
        expect(types.index(KnowledgeBase::Category::Translation.name))
          .to be < types.rindex(KnowledgeBase::Answer::Translation.name)
      end

      it 'ranks a title match above a body match' do
        ids = result.pluck(:id)

        expect(ids.index(translation_id(title_match))).to be < ids.index(translation_id(body_match))
      end

      it 'ranks a tag match above a body match' do
        ids = result.pluck(:id)

        expect(ids.index(translation_id(tag_match))).to be < ids.index(translation_id(body_match))
      end
    end

    describe '#search with highlight options' do
      let(:options) do
        {
          knowledge_base:    knowledge_base,
          locale:            primary_locale,
          scope:             nil,
          flavor:            :agent,
          highlight_options: {
            pre_tags:            ['[HL]'],
            post_tags:           ['[/HL]'],
            number_of_fragments: 1,
            fragment_size:       200,
            no_match_size:       200,
          },
        }
      end

      # A term of its own: searchindex_model_reload reindexes from the database but leaves the
      #   documents of rolled back records behind, and Elasticsearch answers with only 10 hits per
      #   index by default. Sharing a term with another example group lets those leftovers crowd
      #   these two answers out of the response.
      let(:search_term) { 'marimba' }

      # Title matches, body does not - so the body preview can only come from no_match_size.
      let(:title_only_match) do
        create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Marimba maintenance' })
      end

      # Mentions the term three times, each separated by more than the default fragment_size of 100
      #   characters, so Elasticsearch's default of up to five fragments returns several of them.
      let(:long_body_match) do
        create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Percussion upkeep' }).tap do |elem|
          filler = 'Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt ut labore et dolore magna aliqua ut enim ad minim veniam. '
          elem.translations.first.content.update!(body: Array.new(3) { "#{filler}marimba. " }.join)
        end
      end

      def highlight_for(answer)
        instance
          .search(search_term)
          .find { |elem| elem[:id] == translation_id(answer) }
          .fetch(:highlight)
      end

      before do
        title_only_match
        long_body_match
        searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
      end

      it 'marks the term with the requested tags instead of the default marks' do
        expect(highlight_for(title_only_match)['title'].first).to include('[HL]Marimba[/HL]').and(not_include(described_class::HIGHLIGHT_START))
      end

      it 'returns a single fragment even where the default would return several' do
        expect(highlight_for(long_body_match)['content.body'].length).to be 1
      end

      it 'returns a body preview even though only the title matched' do
        expect(highlight_for(title_only_match)['content.body'].first).to be_present
      end
    end

    # A query that matches every term - `*` - marks each of them, and the characters between them
    #   have to come through as themselves. https://github.com/zammad/zammad/issues/6369
    describe '#search with a query that matches every term' do
      def marked(text)
        "#{described_class::HIGHLIGHT_START}#{text}#{described_class::HIGHLIGHT_END}"
      end

      let(:options) do
        {
          knowledge_base:    knowledge_base,
          locale:            primary_locale,
          scope:             nil,
          # Every answer matches, so ask for more than Elasticsearch's default of ten hits -
          #   otherwise the one below can be crowded out of the response.
          from:              0,
          limit:             200,
          highlight_enabled: true,
        }
      end

      let(:ampersand_answer) do
        create(:knowledge_base_answer, :published, category: category, translation_attributes: { title: 'Kalimba & castanets' })
      end

      before do
        ampersand_answer
        searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
      end

      it 'keeps the ampersand between the marked terms' do
        highlight = instance
          .search('*')
          .find { |elem| elem[:id] == translation_id(ampersand_answer) }
          .dig(:highlight, 'title')

        expect(highlight.first).to eq("#{marked('Kalimba')} & #{marked('castanets')}")
      end
    end
  end

  context 'without ES' do
    it 'looks for the database\'s wildcards as they stand' do
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'Printer offline' })
      discount = create(:knowledge_base_answer, :published, category:, translation_attributes: { title: 'A discount of 50% for students' })

      expect(instance.search('%').pluck(:id)).to eq([translation_id(discount)])
    end
  end

  describe '.plain_text' do
    it 'keeps plain text as it is' do
      expect(described_class.plain_text('Warranty & Returns <3')).to eq('Warranty & Returns <3')
    end

    it 'removes markup and keeps its text' do
      expect(described_class.plain_text('<b>Bold</b> topic')).to eq('Bold topic')
    end

    it 'keeps a lone angle bracket, which is text rather than a tag' do
      expect(described_class.plain_text('RAM < 8 GB > 4 GB')).to eq('RAM < 8 GB > 4 GB')
    end

    it 'removes the highlight marks' do
      expect(described_class.plain_text("Marked \u{E000}run\u{E001} here")).to eq('Marked run here')
    end

    it 'returns an empty string for nil' do
      expect(described_class.plain_text(nil)).to eq('')
    end
  end

  describe '#options' do
    let(:built) { instance.options('some term') }

    context 'with agent flavor' do
      let(:options) do
        {
          knowledge_base: knowledge_base,
          locale:         primary_locale,
          scope:          nil,
          flavor:         :agent,
        }
      end

      it 'boosts title and tags' do
        expect(built[:query_extension][:bool][:should]).to eq(
          [
            { match_bool_prefix: { title: { query: 'some term', boost: 3 } } },
            { match_bool_prefix: { tags: { query: 'some term', boost: 2 } } },
          ]
        )
      end

      it 'still sends no fields list, so a plain term keeps matching the index default fields' do
        expect(built).not_to have_key(:query_fields_by_indexes)
      end

      it 'does not boost a field qualified query, which is a filter rather than a ranking' do
        expect(instance.options('publication_state:draft')[:query_extension][:bool]).not_to have_key(:should)
      end
    end

    context 'with public flavor' do
      it 'does not boost, leaving the public site ranking as it was' do
        expect(built[:query_extension][:bool]).not_to have_key(:should)
      end
    end

    context 'without highlight options' do
      it 'asks for the highlight marks, which the callers turn into markup themselves' do
        expect(built[:highlight_options]).to eq({ pre_tags: [described_class::HIGHLIGHT_START], post_tags: [described_class::HIGHLIGHT_END] })
      end
    end

    context 'with highlighting off' do
      let(:options) do
        {
          knowledge_base:    knowledge_base,
          locale:            primary_locale,
          scope:             nil,
          highlight_enabled: false,
        }
      end

      it 'asks for no highlighting at all' do
        expect(built.keys).not_to include(:highlight_options, :highlight_fields_by_indexes)
      end
    end

    it 'asks for the score, which is what merges the per index responses into one ranking' do
      expect(built[:with_score]).to be true
    end

    context 'with an explicit order' do
      let(:options) do
        {
          knowledge_base: knowledge_base,
          locale:         primary_locale,
          scope:          nil,
          order_by:       { updated_at: :desc },
        }
      end

      it 'does not ask for the score, since Elasticsearch already decided the order' do
        expect(built).not_to have_key(:with_score)
      end
    end

    context 'with highlight options' do
      let(:options) do
        {
          knowledge_base:    knowledge_base,
          locale:            primary_locale,
          scope:             nil,
          highlight_options: { pre_tags: ['[HL]'], number_of_fragments: 1 },
        }
      end

      it 'merges them over the defaults, so a caller can override the marks' do
        expect(built[:highlight_options]).to eq({ pre_tags: ['[HL]'], post_tags: [described_class::HIGHLIGHT_END], number_of_fragments: 1 })
      end
    end
  end

  context 'with paging' do
    let(:answers) do
      Array.new(20) do |nth|
        create(:knowledge_base_answer, :published, :with_attachment, category: category, translation_attributes: { title: "#{search_phrase} #{nth}" })
      end
    end

    let(:search_phrase) { 'paging test' }

    let(:options) do
      {
        knowledge_base: knowledge_base,
        locale:         primary_locale,
        scope:          nil,
        order_by:       { id: :desc }
      }
    end

    shared_examples 'verify paging' do |elasticsearch:|
      context "when elastic search is #{elasticsearch}", searchindex: elasticsearch do
        before do
          answers

          handle_elasticsearch(elasticsearch)
        end

        it 'first page is first 5 answers' do
          results = instance.search(search_phrase, pagination: build(:pagination, params: { page: 1, per_page: 5 }))

          first_5 = answers.reverse.slice(0, 5)

          expect(results.pluck(:id)).to eq first_5.map { |answer| answer.translations.first.id }
        end

        it 'second page is next 5 answers' do
          results = instance.search(search_phrase, pagination: build(:pagination, params: { page: 2, per_page: 5 }))

          next_5 = answers.reverse.slice(5, 5)

          expect(results.pluck(:id)).to eq next_5.map { |answer| answer.translations.first.id }
        end

        it 'last page may be partial' do
          results = instance.search(search_phrase, pagination: build(:pagination, params: { page: 4, per_page: 6 }))

          last_page = answers.reverse.slice(18, 6)

          expect(results.pluck(:id)).to eq last_page.map { |answer| answer.translations.first.id }
        end

        it '5th page is empty' do
          results = instance.search(search_phrase, pagination: build(:pagination, params: { page: 5, per_page: 5 }))

          expect(results).to be_blank
        end
      end
    end

    include_examples 'verify paging', elasticsearch: true
    include_examples 'verify paging', elasticsearch: false
  end

  context 'with successful API response' do
    before do
      published_answer
    end

    shared_examples 'verify response' do |elasticsearch:|
      it "ID is an Integer when ES=#{elasticsearch}", searchindex: elasticsearch do
        handle_elasticsearch(elasticsearch)

        first_result = instance.search(published_answer.translations.first.title).first
        expect(first_result[:id]).to be_a(Integer)
      end
    end

    include_examples 'verify response', elasticsearch: true
    include_examples 'verify response', elasticsearch: false
  end

  context 'with user trait and object state' do
    def expected_visibility_instance(ui_identifier)
      options = {
        knowledge_base: knowledge_base,
        locale:         primary_locale,
        scope:          nil,
        flavor:         ui_identifier,
        user:           user
      }

      described_class.new options
    end

    shared_examples 'verify given object is visible' do |searchindex:, ui:|
      it "lists in #{ui} interface when ES=#{searchindex}", searchindex: do
        instance = expected_visibility_instance ui
        object

        handle_elasticsearch(searchindex)

        expect(instance.search(object.translations.first.title)).to be_present
      end
    end

    shared_examples 'verify given object is not visible' do |searchindex:, ui:|
      it "does not list in #{ui} interface when ES=#{searchindex}", searchindex: do
        instance = expected_visibility_instance ui
        object

        handle_elasticsearch(searchindex)

        expect(instance.search(object.translations.first.title)).to be_blank
      end
    end

    shared_examples 'verify given search backend' do |permissions:, ui:|
      [true, false].each do |searchindex|
        if permissions == :all || permissions == ui
          it_behaves_like 'verify given object is visible', searchindex:, ui:
        else
          it_behaves_like 'verify given object is not visible', searchindex:, ui:
        end
      end
    end

    shared_examples 'verify given permissions' do |scope:, trait:, admin:, agent:|
      context "with #{trait} #{scope}" do
        let(:object) { create("knowledge_base_#{scope}", trait, knowledge_base: knowledge_base) }

        include_examples 'verify given user', user_id: :admin, permissions: admin
        include_examples 'verify given user', user_id: :agent, permissions: agent
      end
    end

    shared_examples 'verify given user' do |user_id:, permissions:|
      context "with #{user_id}" do
        let(:user) { create(user_id) }

        include_examples 'verify given search backend', permissions: permissions, ui: :agent
        include_examples 'verify given search backend', permissions: permissions, ui: :public
      end
    end

    include_examples 'verify given permissions', scope: :answer, trait: :published, admin: :all, agent: :all
    include_examples 'verify given permissions', scope: :answer, trait: :internal,  admin: :all, agent: :agent
    include_examples 'verify given permissions', scope: :answer, trait: :draft,     admin: :all, agent: :none
    include_examples 'verify given permissions', scope: :answer, trait: :archived,  admin: :all, agent: :none

    include_examples 'verify given permissions', scope: :category, trait: :empty,                admin: :all, agent: :none
    include_examples 'verify given permissions', scope: :category, trait: :containing_published, admin: :all, agent: :all
    include_examples 'verify given permissions', scope: :category, trait: :containing_internal,  admin: :all, agent: :agent
    include_examples 'verify given permissions', scope: :category, trait: :containing_draft,     admin: :all, agent: :none
    include_examples 'verify given permissions', scope: :category, trait: :containing_archived,  admin: :all, agent: :none

    context 'with granular permissions' do
      before do
        KnowledgeBase::PermissionsUpdate
          .new(category)
          .update! Role.find_by(name: 'Agent') => 'none'
      end

      context 'with reader with limited access to answer' do
        let(:object) { internal_answer }
        let(:user)   { create(:agent)  }

        include_examples 'verify given search backend', permissions: :none, ui: :agent
        include_examples 'verify given search backend', permissions: :none, ui: :public
      end

      context 'with editor with full access to answer' do
        let(:object) { internal_answer }
        let(:user)   { create(:admin)  }

        include_examples 'verify given search backend', permissions: :all, ui: :agent
        include_examples 'verify given search backend', permissions: :all, ui: :public
      end

      context 'with reader with limited access to category' do
        let(:object) { internal_answer.category }
        let(:user)   { create(:agent)  }

        include_examples 'verify given search backend', permissions: :none, ui: :agent
        include_examples 'verify given search backend', permissions: :none, ui: :public
      end

      # The categories a reader can still read are theirs in the agent flavor only.
      context 'with reader with access to another category' do
        let(:user) { create(:agent) }

        context 'with internal answer' do
          let(:object) { internal_answer_in_other_category }

          include_examples 'verify given search backend', permissions: :agent, ui: :agent
          include_examples 'verify given search backend', permissions: :agent, ui: :public
        end

        context 'with its category' do
          let(:object) { internal_answer_in_other_category.category }

          include_examples 'verify given search backend', permissions: :agent, ui: :agent
          include_examples 'verify given search backend', permissions: :agent, ui: :public
        end

        it 'resolves no accessible categories on the help site' do
          objects = [internal_answer_in_other_category, internal_answer_in_other_category.category]
          handle_elasticsearch(false)
          allow(KnowledgeBase::AccessibleCategories).to receive(:for_user).and_call_original

          objects.each { |object| expected_visibility_instance(:public).search(object.translations.first.title) }

          expect(KnowledgeBase::AccessibleCategories).not_to have_received(:for_user)
        end
      end

      context 'with editor with full access to category' do
        let(:object) { internal_answer.category }
        let(:user)   { create(:admin)  }

        include_examples 'verify given search backend', permissions: :all, ui: :agent
        include_examples 'verify given search backend', permissions: :all, ui: :public
      end

      # The agent flavor as well: the client picks the flavor, and an anonymous request with it has
      #   to get the public result rather than an error.
      context 'with unauthorized user and public answer' do
        let(:object) { published_answer }
        let(:user)   { nil }

        include_examples 'verify given search backend', permissions: :all, ui: :agent
        include_examples 'verify given search backend', permissions: :all, ui: :public
      end

      context 'with unauthorized user and internal answer' do
        let(:object) { internal_answer }
        let(:user)   { nil }

        include_examples 'verify given search backend', permissions: :none, ui: :agent
        include_examples 'verify given search backend', permissions: :none, ui: :public
      end

      # Granular grants narrow the knowledge base permissions; a user without any is not narrowed to
      #   nothing but sees published content, like KnowledgeBase::Answer.visible_to_user lets them
      #   browse it.
      context 'with user without knowledge base permission' do
        let(:user) { create(:user, roles: [create(:role, permission_names: %w[ticket.agent])]) }

        context 'with published answer' do
          let(:object) { published_answer }

          include_examples 'verify given search backend', permissions: :all, ui: :agent
          include_examples 'verify given search backend', permissions: :all, ui: :public
        end

        context 'with internal answer' do
          let(:object) { internal_answer }

          include_examples 'verify given search backend', permissions: :none, ui: :agent
          include_examples 'verify given search backend', permissions: :none, ui: :public
        end
      end
    end

    # Own permission rows, not nested under the granular context above: an update replaces an
    #   object's whole permission set and would drop that context's narrowing.
    context 'with editor with limited access to the category' do
      let(:editor_role) { create(:role, permission_names: %w[ticket.agent knowledge_base.editor]) }
      let(:user)        { create(:user, roles: [editor_role]) }

      # Internal and published before it was archived, so only the archived condition keeps it out.
      let(:archived_answer) { create(:knowledge_base_answer, :internal, :published, archived_at: 1.day.ago, category: category) }

      before do
        KnowledgeBase::PermissionsUpdate
          .new(limited_object)
          .update! editor_role => limited_access
      end

      # Narrowed at the root, so the editor edits no category at all.
      context 'when the access to the whole knowledge base is none' do
        let(:limited_object) { knowledge_base }
        let(:limited_access) { 'none' }

        context 'with published answer' do
          let(:object) { published_answer }

          include_examples 'verify given search backend', permissions: :all, ui: :agent
          include_examples 'verify given search backend', permissions: :all, ui: :public
        end

        context 'with draft answer' do
          let(:object) { draft_answer }

          include_examples 'verify given search backend', permissions: :none, ui: :agent
          include_examples 'verify given search backend', permissions: :none, ui: :public
        end

        context 'with archived answer' do
          let(:object) { archived_answer }

          include_examples 'verify given search backend', permissions: :none, ui: :agent
          include_examples 'verify given search backend', permissions: :none, ui: :public
        end
      end

      context 'when the access is none' do
        let(:limited_object) { category }
        let(:limited_access) { 'none' }

        context 'with category containing published answer' do
          let(:object) { published_answer.category }

          include_examples 'verify given search backend', permissions: :all, ui: :agent
          include_examples 'verify given search backend', permissions: :all, ui: :public
        end

        context 'with internal answer' do
          let(:object) { internal_answer }

          include_examples 'verify given search backend', permissions: :none, ui: :agent
          include_examples 'verify given search backend', permissions: :none, ui: :public
        end

        context 'with draft answer' do
          let(:object) { draft_answer }

          include_examples 'verify given search backend', permissions: :none, ui: :agent
          include_examples 'verify given search backend', permissions: :none, ui: :public
        end

        context 'with archived answer' do
          let(:object) { archived_answer }

          include_examples 'verify given search backend', permissions: :none, ui: :agent
          include_examples 'verify given search backend', permissions: :none, ui: :public
        end

        context 'with published answer' do
          let(:object) { published_answer }

          include_examples 'verify given search backend', permissions: :all, ui: :agent
          include_examples 'verify given search backend', permissions: :all, ui: :public
        end

        context 'with category containing internal answer' do
          let(:object) { internal_answer.category }

          include_examples 'verify given search backend', permissions: :none, ui: :agent
          include_examples 'verify given search backend', permissions: :none, ui: :public
        end

        context 'with draft answer in a category the editor still edits' do
          let(:object) { draft_answer_in_other_category }

          include_examples 'verify given search backend', permissions: :all, ui: :agent
          include_examples 'verify given search backend', permissions: :all, ui: :public
        end
      end

      context 'when the access is reader' do
        let(:limited_object) { category }
        let(:limited_access) { 'reader' }

        context 'with internal answer' do
          let(:object) { internal_answer }

          include_examples 'verify given search backend', permissions: :agent, ui: :agent
          include_examples 'verify given search backend', permissions: :agent, ui: :public
        end

        context 'with draft answer' do
          let(:object) { draft_answer }

          include_examples 'verify given search backend', permissions: :none, ui: :agent
          include_examples 'verify given search backend', permissions: :none, ui: :public
        end

        context 'with archived answer' do
          let(:object) { archived_answer }

          include_examples 'verify given search backend', permissions: :none, ui: :agent
          include_examples 'verify given search backend', permissions: :none, ui: :public
        end

        context 'with category containing internal answer' do
          let(:object) { internal_answer.category }

          include_examples 'verify given search backend', permissions: :agent, ui: :agent
          include_examples 'verify given search backend', permissions: :agent, ui: :public
        end
      end
    end
  end

  context 'with a category whose published content is translated to another locale only' do
    let(:user) { nil }

    def search_category(kb_locale)
      described_class
        .new(knowledge_base:, locale: kb_locale, flavor: :public, index: KnowledgeBase::Category::Translation.name)
        .search('Polyglot')
        .pluck(:id)
    end

    before do
      category.translations.first.update!(title: 'Polyglot category')
      create(:knowledge_base_category_translation, category:, kb_locale: alternative_locale, title: 'Polyglot category (lt)')
      create(:knowledge_base_answer, :published, category:, translation_attributes: { kb_locale: alternative_locale })
    end

    [true, false].each do |searchindex|
      context "when ES=#{searchindex}", searchindex: do
        before { handle_elasticsearch(searchindex) }

        it 'lists the category in that locale' do
          expect(search_category(alternative_locale)).to eq([category.translations.find_by(kb_locale: alternative_locale).id])
        end

        it 'does not list the category in the locale without published content' do
          expect(search_category(primary_locale)).to be_empty
        end
      end
    end
  end
end
