# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::KnowledgeBase::CategorySubcategories, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:query) do
    <<~GQL
      query knowledgeBaseCategorySubcategories($categoryId: ID, $locale: String) {
        knowledgeBaseCategorySubcategories(categoryId: $categoryId, locale: $locale) {
          category { isVisiblePublicly translationMissing breadcrumb { id title visibility } }
          subcategories {
            id title visibility translationMissing answerCount subcategoryCount directAnswerCount directSubcategoryCount
            breadcrumb { id title }
          }
        }
      }
    GQL
  end
  let(:category_id) { nil }
  let(:locale)      { nil }
  let(:variables)   { { categoryId: category_id, locale: }.compact }

  def result_categories
    gql.result.data['subcategories']
  end

  def category_node(record)
    result_categories.find { |c| c['id'] == gql.id(record) }
  end

  context 'when at the knowledge base root' do
    before do
      published_answer               # category => public content
      draft_answer_in_other_category # other_category => draft-only content
      gql.execute(query, variables:)
    end

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'has no opened category at the root' do
        expect(gql.result.data['category']).to be_nil
      end

      it 'lists all root categories, including draft-only ones' do
        expect(result_categories.pluck('id')).to include(gql.id(category), gql.id(other_category))
      end

      it 'color-codes categories by their highest content visibility', :aggregate_failures do
        expect(category_node(category)).to include('visibility' => 'published')
        expect(category_node(other_category)).to include('visibility' => 'draft')
      end

      it 'color-codes a category with only archived content as archived' do
        create(:knowledge_base_answer, :archived, category: other_category)
        gql.execute(query, variables:)

        expect(category_node(other_category)).to include('visibility' => 'archived')
      end
    end

    context 'with an agent (reader)', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      it 'hides categories without internal or public content', :aggregate_failures do
        ids = result_categories.pluck('id')
        expect(ids).to include(gql.id(category))
        expect(ids).not_to include(gql.id(other_category))
      end
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'lists only categories with public content', :aggregate_failures do
        ids = result_categories.pluck('id')
        expect(ids).to include(gql.id(category))
        expect(ids).not_to include(gql.id(other_category))
      end
    end
  end

  context 'when opening a category' do
    let(:category_id) { gql.id(category) }

    before do
      published_answer                # category => public
      published_answer_in_subcategory # subcategory => public
      gql.execute(query, variables:)
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'returns the opened category with its breadcrumb path and content visibility' do
        expect(gql.result.data.dig('category', 'breadcrumb')).to eq(
          [{ 'id' => gql.id(category), 'title' => category.translation_primary.title, 'visibility' => 'published' }]
        )
      end

      it 'reports the opened public category as publicly visible' do
        expect(gql.result.data.dig('category', 'isVisiblePublicly')).to be(true)
      end

      it 'lists the visible child categories' do
        expect(result_categories.pluck('id')).to eq([gql.id(subcategory)])
      end

      it 'gives each subcategory its own breadcrumb, so an opened one needs no extra fetch' do
        expect(category_node(subcategory)['breadcrumb']).to eq(
          [
            { 'id' => gql.id(category), 'title' => category.translation_primary.title },
            { 'id' => gql.id(subcategory), 'title' => subcategory.translation_primary.title },
          ]
        )
      end
    end
  end

  context 'when opening a non-public category' do
    let(:category_id) { gql.id(other_category) }

    context 'with a reader on internal-only content', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      before do
        internal_answer_in_other_category # other_category => internal content
        gql.execute(query, variables:)
      end

      it 'reports the category as not publicly visible' do
        expect(gql.result.data.dig('category', 'isVisiblePublicly')).to be(false)
      end
    end

    context 'with an editor on draft-only content', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      before do
        draft_answer_in_other_category # other_category => draft-only content
        gql.execute(query, variables:)
      end

      # The flag is content-based, not permission-based; the editor's ability to
      #   preview drafts is added on the client (it knows the editor role).
      it 'reports the category as not publicly visible even for an editor' do
        expect(gql.result.data.dig('category', 'isVisiblePublicly')).to be(false)
      end
    end
  end

  # Opening a category is authorized with the same rule as listing it, so a user
  #   cannot reach (by URL) a category that would never appear for them.
  context 'when opening a category the user may not browse' do
    let(:category_id) { gql.id(other_category) }

    context 'with a reader on a draft-only category', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      before do
        draft_answer_in_other_category # other_category => draft-only content
        gql.execute(query, variables:)
      end

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with a customer on an internal-only category', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      before do
        internal_answer_in_other_category # other_category => internal content
        gql.execute(query, variables:)
      end

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    # The category is visible in another locale, so the locale-agnostic
    #   authorization alone would let it through; the query must still enforce
    #   the browsed locale (matching what the listing hides).
    context 'when opening it in a locale its content is not translated to' do
      let(:locale) { locale_name } # browse the primary locale

      before do
        # other_category has internal content only in the alternative locale.
        create(:knowledge_base_answer, :internal, category:               other_category,
                                                  translation_attributes: { kb_locale: alternative_locale })
      end

      context 'with a reader', authenticated_as: :agent do
        let(:agent) { create(:agent) }

        it 'is forbidden in the untranslated locale' do
          gql.execute(query, variables:)
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'with an editor', authenticated_as: :admin do
        let(:admin) { create(:admin) }

        it 'still opens the category (editors see untranslated content)' do
          gql.execute(query, variables:)
          # Data present (no Forbidden), category color-coded draft in this locale.
          expect(gql.result.data.dig('category', 'isVisiblePublicly')).to be(false)
        end
      end
    end
  end

  context 'with subtree answer counts' do
    let(:category_id) { nil }

    before do
      published_answer                             # category, public
      internal_answer                              # category, internal
      draft_answer                                 # category, draft
      archived_answer                              # category, archived (counted for editors only)
      published_answer_in_subcategory              # subcategory, public
      create(:knowledge_base_category, parent: subcategory) # deeper descendant (no answers)
    end

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'counts published + internal + draft + archived across the whole subtree' do
        gql.execute(query, variables:)
        expect(category_node(category)).to include('answerCount' => 5)
      end

      it 'counts the visible categories across the whole subtree' do
        gql.execute(query, variables:)
        expect(category_node(category)).to include('subcategoryCount' => 2)
      end

      it 'counts only the immediate level for the direct counts', :aggregate_failures do
        gql.execute(query, variables:)
        # Direct answers in the category (published + internal + draft +
        #   archived), and only its immediate child (not the deeper descendant).
        expect(category_node(category)).to include('directAnswerCount' => 4, 'directSubcategoryCount' => 1)
      end
    end

    context 'with an agent (reader)', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      it 'counts internally and publicly published answers across the subtree' do
        gql.execute(query, variables:)
        expect(category_node(category)).to include('answerCount' => 3)
      end
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'counts only published answers across the subtree' do
        gql.execute(query, variables:)
        expect(category_node(category)).to include('answerCount' => 2)
      end
    end
  end

  context 'when many categories are listed', authenticated_as: :admin do
    let(:admin)       { create(:admin) }
    let(:category_id) { nil }

    def answer_table_query_count
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
        queries << payload[:sql] if payload[:sql].include?('knowledge_base_answers')
      end
      gql.execute(query, variables:)
      queries.size
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    # The subtree counts/visibility are resolved in one batch; the number of
    #   answer queries must stay constant as the category list grows (an editor
    #   is used so per-node authorization does not itself touch answers).
    it 'resolves subtree data in a constant number of answer queries' do
      published_answer
      baseline = answer_table_query_count

      create_list(:knowledge_base_category, 5, knowledge_base:).each do |extra|
        create(:knowledge_base_answer, :published, category: extra)
      end

      expect(answer_table_query_count).to eq(baseline)
    end
  end

  context 'when granular category permissions are configured' do
    let(:reader_role) { create(:role, permission_names: %w[knowledge_base.reader]) }
    let(:reader)      { create(:user, roles: [reader_role]) }
    let(:category_id) { nil }

    before do
      internal_answer                   # category => internal content
      internal_answer_in_other_category # other_category => internal content
      create(:knowledge_base_permission, permissionable: other_category, role: reader_role, access: 'none')
      gql.execute(query, variables:)
    end

    context 'with a reader denied access to a category', authenticated_as: :reader do
      it 'hides the denied category while keeping the permitted one', :aggregate_failures do
        ids = result_categories.pluck('id')
        expect(ids).to include(gql.id(category))
        expect(ids).not_to include(gql.id(other_category))
      end
    end

    # A granular denial must also block opening the category by URL, not only
    #   hide it from the listing.
    context 'with a reader opening a denied category directly', authenticated_as: :reader do
      let(:category_id) { gql.id(other_category) }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when the knowledge base is inactive' do
    let(:category_id) { gql.id(category) }

    before do
      published_answer # category => public content
      knowledge_base.update!(active: false)
      gql.execute(query, variables:)
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'returns no browsable content from the inactive knowledge base' do
        expect(gql.result.data).to eq('category' => nil, 'subcategories' => [])
      end
    end
  end

  # Mirrors the agent app: content only counts in a locale it is translated to.
  #   Non-editors do not see untranslated categories/answers at all; editors see
  #   them, but color-coded as draft in the browsed locale.
  context 'when content is not translated to the browsed locale' do
    before do
      published_answer # category => public content, translated in the primary locale

      # other_category => internal content translated ONLY to the alternative locale
      create(:knowledge_base_answer, :internal, category: other_category, translation_attributes: { kb_locale: alternative_locale })

      gql.execute(query, variables:)
    end

    context 'with an agent (reader) browsing the primary locale', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      it 'hides the category whose content is untranslated', :aggregate_failures do
        ids = result_categories.pluck('id')
        expect(ids).to include(gql.id(category))
        expect(ids).not_to include(gql.id(other_category))
      end
    end

    context 'with an agent (reader) browsing the alternative locale', authenticated_as: :agent do
      let(:agent)  { create(:agent) }
      let(:locale) { alternative_locale.system_locale.locale }

      it 'shows the category in the locale its content is translated to' do
        expect(result_categories.pluck('id')).to include(gql.id(other_category))
      end
    end

    context 'with an admin (editor) browsing the primary locale', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'still shows the category, color-coded as draft in this locale', :aggregate_failures do
        expect(category_node(other_category)).to include('visibility' => 'draft')
        # The untranslated answer is still browsable for editors, so it is counted.
        expect(category_node(other_category)).to include('answerCount' => 1)
      end

      it 'color-codes the category by its content visibility in the browsed locale' do
        gql.execute(query, variables: { locale: alternative_locale.system_locale.locale })
        expect(category_node(other_category)).to include('visibility' => 'internal')
      end
    end
  end

  # The title-translation flag is independent of content visibility: a category
  #   can be visible in a locale yet still show a fallback title when its own
  #   name is untranslated there.
  context 'when a category title is not translated to the browsed locale' do
    let(:category_id) { nil }
    let(:locale)      { alternative_locale.system_locale.locale }

    let(:translated_category) do
      create(:knowledge_base_category, knowledge_base:).tap do |cat|
        create(:knowledge_base_category_translation, category: cat, kb_locale: alternative_locale)
      end
    end

    before do
      published_answer    # category => primary-locale title only
      translated_category # also has an alternative-locale title
      gql.execute(query, variables:)
    end

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'flags categories whose title falls back from a missing translation', :aggregate_failures do
        expect(category_node(category)).to include('translationMissing' => true)
        expect(category_node(translated_category)).to include('translationMissing' => false)
      end
    end
  end

  context 'when opening a category untranslated in the browsed locale' do
    let(:category_id) { gql.id(category) }
    let(:locale)      { alternative_locale.system_locale.locale }

    before do
      published_answer # category => primary-locale title only
      gql.execute(query, variables:)
    end

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'reports the opened category as missing its translation' do
        expect(gql.result.data.dig('category', 'translationMissing')).to be(true)
      end
    end
  end
end
