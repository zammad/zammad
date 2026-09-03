# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Which categories are listed, with which counts, titles and breadcrumbs, is covered by
#   spec/services/service/knowledge_base/category_content_spec.rb — this covers the GraphQL surface
#   only: the payload the types render from the batched result, and authorization.
RSpec.describe Gql::Queries::KnowledgeBase::CategorySubcategories, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:query) do
    <<~GQL
      query knowledgeBaseCategorySubcategories($categoryId: ID, $locale: String, $sortingMode: EnumKnowledgeBaseSortingMode) {
        knowledgeBaseCategorySubcategories(categoryId: $categoryId, locale: $locale, sortingMode: $sortingMode) {
          category {
            isVisiblePublicly
            categorySortingMode
            answerSortingMode
            editedAt
            translation(locale: $locale) { title kbLocale { systemLocale { locale } } }
            breadcrumb { id translation(locale: $locale) { title } visibility }
          }
          subcategories {
            id visibility categorySortingMode answerSortingMode editedAt
            answerCount subcategoryCount directAnswerCount directSubcategoryCount
            translation(locale: $locale) { title kbLocale { systemLocale { locale } } }
            categoryIcon iconSet
            breadcrumb { id translation(locale: $locale) { title } }
          }
        }
      }
    GQL
  end
  let(:category_id)  { nil }
  let(:locale)       { nil }
  let(:sorting_mode) { nil }
  let(:variables)    { { categoryId: category_id, locale:, sortingMode: sorting_mode }.compact }

  def result_categories
    gql.result.data['subcategories']
  end

  def category_node(record)
    result_categories.find { |c| c['id'] == gql.id(record) }
  end

  # Which order each mode produces is Service::KnowledgeBase::CategoryContent's business; this
  #   covers that the argument reaches it, so the sorting bar can preview a mode without saving it
  #   first — and that the node keeps reporting the mode it is actually stored with, which is what
  #   the bar compares a picked one against.
  context 'with a previewed sorting mode' do
    let(:sorting_mode) { 'alphabetical' }

    before do
      published_answer
      draft_answer_in_other_category
      gql.execute(query, variables:)
    end

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'lists in the previewed mode' do
        titles = result_categories.map { |category| category.dig('translation', 'title') }

        expect(titles).to eq(titles.sort_by(&:downcase))
      end

      it 'still reports the stored mode' do
        expect(knowledge_base.reload.category_sorting_mode).to eq('manual')
      end
    end
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

      it 'lists the categories the service resolved' do
        expect(result_categories.pluck('id')).to include(gql.id(category), gql.id(other_category))
      end

      it 'renders the content visibility the service resolved' do
        expect(category_node(category)).to include('visibility' => 'published')
      end

      # Resolved by the type through a batch loader rather than by the service.
      it 'exposes the icon set of the knowledge base the category belongs to' do
        expect(category_node(category)).to include('iconSet' => 'FontAwesome')
      end

      it 'exposes a dashed icon set verbatim' do
        knowledge_base.update!(iconset: 'Simple-Line-Icons')
        gql.execute(query, variables:)

        expect(category_node(category)).to include('iconSet' => 'Simple-Line-Icons')
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
          [{ 'id'          => gql.id(category),
             'translation' => { 'title' => category.translation_primary.title },
             'visibility'  => 'published' }]
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
            { 'id' => gql.id(category), 'translation' => { 'title' => category.translation_primary.title } },
            { 'id' => gql.id(subcategory), 'translation' => { 'title' => subcategory.translation_primary.title } },
          ]
        )
      end

      # Every listed category carries the modes its own content is ordered by, so the browse view can
      #   show the pickers of the opened category and of each card without a second fetch.
      it 'gives the opened category and each subcategory their sorting modes', :aggregate_failures do
        category.update!(category_sorting_mode: 'alphabetical')
        subcategory.update!(category_sorting_mode: 'last_update')
        gql.execute(query, variables:)

        expect(gql.result.data.dig('category', 'categorySortingMode')).to eq('alphabetical')
        expect(category_node(subcategory)['categorySortingMode']).to eq('last_update')
      end

      # The combination a single column could not express: one category, its two lists in
      #   different modes.
      it 'gives a category the two modes of its two lists independently', :aggregate_failures do
        category.update!(category_sorting_mode: 'alphabetical', answer_sorting_mode: 'manual')
        gql.execute(query, variables:)

        expect(gql.result.data.dig('category', 'categorySortingMode')).to eq('alphabetical')
        expect(gql.result.data.dig('category', 'answerSortingMode')).to eq('manual')
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

  # The counts themselves come from the service; the type only has to hand the batched numbers to
  #   the right node.
  context 'with subtree answer counts', authenticated_as: :admin do
    let(:admin)       { create(:admin) }
    let(:category_id) { nil }

    before do
      published_answer                                      # category, public
      published_answer_in_subcategory                       # subcategory, public
      create(:knowledge_base_category, parent: subcategory) # deeper descendant (no answers)
      gql.execute(query, variables:)
    end

    it 'exposes the subtree and direct counts of each category', :aggregate_failures do
      expect(category_node(category)).to include('answerCount' => 2, 'subcategoryCount' => 2)
      expect(category_node(category)).to include('directSubcategoryCount' => 1)
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

  # The editorial timestamp the `last_update` mode orders by, resolved off the same translation the
  #   title comes from — so a card can show why it sits where it does.
  describe 'the editorial timestamp' do
    let(:category_id) { gql.id(category) }

    before { published_answer_in_subcategory } # category => subcategory => public content

    context 'with an admin (editor)', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      it 'is given for the opened category and for each listed one', :aggregate_failures do
        edited_at = 3.days.ago
        subcategory.translation_primary.update!(edited_at:)

        gql.execute(query, variables:)
        expect(gql.result.data.dig('category', 'editedAt')).to eq(category.translation_primary.reload.edited_at.iso8601)
        expect(category_node(subcategory)['editedAt']).to eq(edited_at.iso8601)
      end

      def translation_query_count
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe('sql.active_record') do |*, payload|
          queries << payload[:sql] if payload[:sql].include?('knowledge_base_category_translations')
        end
        gql.execute(query, variables:)
        queries.size
      ensure
        ActiveSupport::Notifications.unsubscribe(subscriber)
      end

      # Batched with the titles, so dating a listing does not add a query per card.
      it 'costs no extra query per listed category' do
        baseline = translation_query_count

        create_list(:knowledge_base_category, 5, knowledge_base:, parent: category).each do |extra|
          create(:knowledge_base_answer, :published, category: extra)
        end

        expect(translation_query_count).to eq(baseline)
      end
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      before { gql.execute(query, variables:) }

      it 'is given for a publicly readable category', :aggregate_failures do
        expect(gql.result.data.dig('category', 'editedAt')).to be_present
        expect(gql.result.data.dig('category', 'isVisiblePublicly')).to be(true)
      end
    end

    context 'with an agent (reader)', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      before { gql.execute(query, variables:) }

      it 'is given to a reader' do
        expect(gql.result.data.dig('category', 'editedAt')).to be_present
      end
    end
  end

  # A granular denial must also block opening the category by URL, not only hide it from the
  #   listing the service resolves.
  context 'when granular category permissions are configured' do
    let(:reader_role) { create(:role, permission_names: %w[knowledge_base.reader]) }
    let(:reader)      { create(:user, roles: [reader_role]) }
    let(:category_id) { gql.id(other_category) }

    before do
      internal_answer_in_other_category # other_category => internal content
      create(:knowledge_base_permission, permissionable: other_category, role: reader_role, access: 'none')
      gql.execute(query, variables:)
    end

    context 'with a reader opening a denied category directly', authenticated_as: :reader do
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

      it 'is rejected' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  # Which locale a name came from is independent of content visibility: a category can be visible
  #   in a locale yet still be named from a fallback when its own name is untranslated there. The
  #   answer says so itself - the returned translation carries the locale it belongs to.
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

      def translation_locale(record)
        category_node(record).dig('translation', 'kbLocale', 'systemLocale', 'locale')
      end

      it 'names an untranslated category from its fallback locale', :aggregate_failures do
        expect(translation_locale(category)).to eq(primary_locale.system_locale.locale)
        expect(translation_locale(translated_category)).to eq(alternative_locale.system_locale.locale)
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

      it 'names the opened category from its fallback locale' do
        expect(gql.result.data.dig('category', 'translation', 'kbLocale', 'systemLocale', 'locale'))
          .to eq(primary_locale.system_locale.locale)
      end
    end
  end

  # The two halves of a category's locale-dependent data are resolved against *different* locales,
  #   and this is the case that tells them apart: the name falls back to the locale that has one,
  #   while the counts stay on the locale being browsed. Resolving the counts from the returned
  #   translation instead would report the fallback locale's numbers here (2 answers rather than 1)
  #   - see Gql::Types::KnowledgeBase::CategoryType.
  context 'when a category is named from a fallback locale but has content in the browsed one' do
    let(:category_id) { nil }
    let(:locale)      { alternative_locale.system_locale.locale }

    before do
      # `other_category` keeps its primary-locale name only, and holds a different number of
      #   published answers per locale - two in the primary, one in the browsed alternative.
      create_list(:knowledge_base_answer, 2, :published, category: other_category)
      create(:knowledge_base_answer, :published, category:               other_category,
                                                 translation_attributes: { kb_locale: alternative_locale })
      gql.execute(query, variables:)
    end

    context 'with a customer (public)', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'names it from the fallback locale, but counts the browsed one', :aggregate_failures do
        expect(category_node(other_category).dig('translation', 'kbLocale', 'systemLocale', 'locale'))
          .to eq(primary_locale.system_locale.locale)
        expect(category_node(other_category)).to include('answerCount' => 1)
      end
    end
  end
end
