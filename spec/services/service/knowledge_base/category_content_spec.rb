# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::CategoryContent do
  subject(:content) do
    described_class.with_current_user(user).execute(knowledge_base:, category: opened_category, locale:, sorting_mode:)
  end

  include_context 'basic Knowledge Base'

  let(:user)            { create(:admin) }
  let(:opened_category) { nil }
  let(:locale)          { primary_locale }
  let(:sorting_mode)    { nil }

  let(:editor)   { create(:admin) }
  let(:reader)   { create(:agent) }
  let(:customer) { create(:customer) }

  def subcategory_ids
    content[:subcategories].map(&:id)
  end

  def details_of(record)
    content[:category_details][record.id]
  end

  describe 'visible children' do
    before do
      published_answer               # category => public content
      draft_answer_in_other_category # other_category => draft-only content
    end

    context 'with an editor' do
      let(:user) { editor }

      it 'lists all categories, including draft-only ones' do
        expect(subcategory_ids).to include(category.id, other_category.id)
      end

      it 'sorts them by position' do
        expect(subcategory_ids).to eq(content[:subcategories].sort_by(&:position).map(&:id))
      end
    end

    context 'with a reader' do
      let(:user) { reader }

      it 'hides categories without internal or public content', :aggregate_failures do
        expect(subcategory_ids).to include(category.id)
        expect(subcategory_ids).not_to include(other_category.id)
      end
    end

    context 'with a public user' do
      let(:user) { customer }

      it 'lists only categories with public content', :aggregate_failures do
        expect(subcategory_ids).to include(category.id)
        expect(subcategory_ids).not_to include(other_category.id)
      end
    end

    context 'when a granular permission denies a category' do
      let(:reader_role) { create(:role, permission_names: %w[knowledge_base.reader]) }
      let(:user)        { create(:user, roles: [reader_role]) }

      before do
        internal_answer                   # category => internal content
        internal_answer_in_other_category # other_category => internal content
        create(:knowledge_base_permission, permissionable: other_category, role: reader_role, access: 'none')
      end

      it 'hides the denied category while keeping the permitted one', :aggregate_failures do
        expect(subcategory_ids).to include(category.id)
        expect(subcategory_ids).not_to include(other_category.id)
      end
    end

    context 'when a category is opened' do
      let(:opened_category) { category }

      before { published_answer_in_subcategory }

      it 'lists the children of that category' do
        expect(subcategory_ids).to eq([subcategory.id])
      end

      it 'returns the opened category itself' do
        expect(content[:category]).to eq(category)
      end
    end
  end

  describe 'sorting mode' do
    # The mode belongs to the node whose content is listed: the knowledge base at the root, the
    #   opened category below it.
    let(:sorting_node)    { opened_category || knowledge_base }
    let(:first_category)  { titled(category, 'Alpha') }
    let(:second_category) { titled(sibling_of(first_category), 'beta') }
    let(:third_category)  { titled(sibling_of(first_category), 'Gamma') }

    def titled(record, title)
      record.translation_primary.update!(title:)
      record
    end

    def sibling_of(record)
      create(:knowledge_base_category, knowledge_base:, parent: record.parent)
    end

    def order_of(*records)
      subcategory_ids & records.map(&:id)
    end

    before do
      third_category
      first_category
      second_category
    end

    shared_examples 'ordering the listed categories' do
      it 'keeps the hand-arranged positions in the manual mode' do
        third_category.move_to_top

        expect(order_of(first_category, second_category, third_category).first).to eq(third_category.id)
      end

      context 'with the alphabetical mode' do
        before { sorting_node.update!(category_sorting_mode: 'alphabetical') }

        it 'orders by title, ignoring case' do
          expect(order_of(first_category, second_category, third_category))
            .to eq([first_category.id, second_category.id, third_category.id])
        end

        # Comparing titles in Ruby would order these by codepoint and file every accented one
        #   after "Zebra"; the database folds them onto their base letter. The listing has to
        #   follow the database, since that is what the help site renders.
        context 'with non-ASCII titles' do
          before do
            titled(first_category, 'Ähre')
            titled(second_category, 'Šalis')
            titled(third_category, 'Zebra')
          end

          it 'folds accented titles onto their base letter' do
            expect(order_of(first_category, second_category, third_category))
              .to eq([first_category.id, second_category.id, third_category.id])
          end
        end

        # A category is shown under its fallback title when untranslated, so that is the title it
        #   has to sort under too.
        context 'with a category untranslated in the browsed locale' do
          let(:locale) { alternative_locale }

          before { create(:knowledge_base_category_translation, category: third_category, kb_locale: alternative_locale, title: 'Aardvark') }

          it 'sorts the untranslated ones under their fallback title' do
            expect(order_of(first_category, second_category, third_category))
              .to eq([third_category.id, first_category.id, second_category.id])
          end
        end
      end

      # What the sorting bar previews with: the listing is fetched in the mode the editor picked, so
      #   what they see before saving is the very order saving produces.
      context 'with a previewed sorting mode' do
        context 'when it differs from the stored one' do
          let(:sorting_mode) { 'alphabetical' }

          before { third_category.move_to_top }

          it 'lists in the previewed mode' do
            expect(order_of(first_category, second_category, third_category))
              .to eq([first_category.id, second_category.id, third_category.id])
          end

          it 'leaves the stored mode alone' do
            content

            expect(sorting_node.reload.category_sorting_mode).to eq('manual')
          end
        end

        # Nothing to preview is the ordinary case, and it is what every browse without the bar up
        #   passes.
        context 'when none is given' do
          before do
            sorting_node.update!(category_sorting_mode: 'alphabetical')
            third_category.move_to_top
          end

          it 'lists in the stored mode' do
            expect(order_of(first_category, second_category, third_category))
              .to eq([first_category.id, second_category.id, third_category.id])
          end
        end
      end

      context 'with the last update mode' do
        before do
          sorting_node.update!(category_sorting_mode: 'last_update')

          travel_to(1.hour.from_now)  { second_category.translation_primary.update!(title: 'beta, edited') }
          travel_to(2.hours.from_now) { first_category.translation_primary.update!(title: 'Alpha, edited') }
        end

        it 'orders by the most recently edited first' do
          expect(order_of(first_category, second_category, third_category))
            .to eq([first_category.id, second_category.id, third_category.id])
        end

        # A category is dated by the content below it, not only by its own title.
        it 'counts an edit to an answer filed in the category' do
          answer = create(:knowledge_base_answer, category: third_category)

          travel_to(3.hours.from_now) { answer.translation.update!(title: 'Answer, edited') }

          expect(order_of(first_category, second_category, third_category).first).to eq(third_category.id)
        end

        # The `updated_at` proxy this mode used to read moved for both of these, floating a category
        #   to the top of the listing for a change nobody made to its content.
        it 'is unmoved by a reorder or a sorting-mode switch' do
          travel_to(3.hours.from_now) do
            third_category.move_to_top
            third_category.update!(answer_sorting_mode: 'alphabetical')
          end

          expect(order_of(first_category, second_category, third_category))
            .to eq([first_category.id, second_category.id, third_category.id])
        end
      end
    end

    context 'when browsing the knowledge base root' do
      let(:opened_category) { nil }

      include_examples 'ordering the listed categories'
    end

    context 'when browsing inside a category' do
      let(:opened_category) { create(:knowledge_base_category, knowledge_base:) }
      let(:first_category)  { titled(create(:knowledge_base_category, knowledge_base:, parent: opened_category), 'Alpha') }

      include_examples 'ordering the listed categories'
    end
  end

  describe 'content visibility' do
    context 'with an editor' do
      let(:user) { editor }

      it 'reports the highest content visibility of the subtree', :aggregate_failures do
        published_answer
        draft_answer_in_other_category

        expect(details_of(category)).to include(visibility: :published)
        expect(details_of(other_category)).to include(visibility: :draft)
      end

      it 'reports a category with only archived content as archived' do
        create(:knowledge_base_answer, :archived, category: other_category)

        expect(details_of(other_category)).to include(visibility: :archived)
      end
    end
  end

  describe 'subtree counts' do
    before do
      published_answer                                      # category, public
      internal_answer                                       # category, internal
      draft_answer                                          # category, draft
      archived_answer                                       # category, archived (editors only)
      published_answer_in_subcategory                       # subcategory, public
      create(:knowledge_base_category, parent: subcategory) # deeper descendant, no answers
    end

    context 'with an editor' do
      let(:user) { editor }

      it 'counts published, internal, draft and archived answers across the whole subtree' do
        expect(details_of(category)).to include(answer_count: 5)
      end

      it 'counts the visible categories across the whole subtree' do
        expect(details_of(category)).to include(subcategory_count: 2)
      end

      it 'counts only the immediate level for the direct counts' do
        expect(details_of(category)).to include(direct_answer_count: 4, direct_subcategory_count: 1)
      end
    end

    context 'with a reader' do
      let(:user) { reader }

      it 'counts internally and publicly published answers across the subtree' do
        expect(details_of(category)).to include(answer_count: 3)
      end
    end

    context 'with a public user' do
      let(:user) { customer }

      it 'counts only published answers across the subtree' do
        expect(details_of(category)).to include(answer_count: 2)
      end
    end
  end

  describe 'deletability' do
    let(:user)            { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }
    let(:opened_category) { category }

    # Deletability is the one detail that must not follow the current user's view of the tree:
    #   `destroy!` is refused by any answer below the category, including the ones this user may
    #   not see. A draft answer is exactly that case for a reader — it is not counted among the
    #   visible answers, yet it still blocks the delete.
    context 'with an answer the current user cannot see' do
      before { draft_answer }

      it 'reports the category as not deletable', :aggregate_failures do
        expect(details_of(category)).to include(deletable: false)
        expect(details_of(category)).to include(answer_count: 0)
      end
    end

    context 'without any content' do
      it 'reports the category as deletable' do
        expect(details_of(category)).to include(deletable: true)
      end
    end

    context 'with a subcategory' do
      before { subcategory }

      it 'reports the category as not deletable' do
        expect(details_of(category)).to include(deletable: false)
      end
    end
  end

  describe 'breadcrumbs' do
    let(:opened_category) { category }

    before { published_answer_in_subcategory }

    it 'returns the ancestor path of the opened category' do
      expect(content[:category_breadcrumbs][category.id]).to eq([category])
    end

    # Cached for the child too, so opening it needs no extra fetch for the header.
    it 'returns the ancestor path of every rendered child' do
      expect(content[:category_breadcrumbs][subcategory.id]).to eq([category, subcategory])
    end
  end

  describe 'translations' do
    before { published_answer }

    it 'resolves the translation of the browsed locale' do
      expect(content[:category_translations][category.id]).to eq(category.translation_primary)
    end

    # Content only counts in a locale it is translated to, but a name falls back — so a category
    #   can be shown named from another locale, which the translation it is named by says itself.
    context 'with a locale the title is not translated to' do
      let(:locale) { alternative_locale }

      it 'falls back to the primary translation' do
        expect(content[:category_translations][category.id]).to eq(category.translation_primary)
      end

      context 'when the title is translated there' do
        let!(:alternative_translation) do
          create(:knowledge_base_category_translation, category:, kb_locale: alternative_locale)
        end

        it 'resolves that one' do
          expect(content[:category_translations][category.id]).to eq(alternative_translation)
        end
      end
    end
  end

  # Mirrors the agent app: content only counts in a locale it is translated to. Non-editors do not
  #   see untranslated content at all; editors see it, color-coded as draft in the browsed locale.
  describe 'content in another locale' do
    before do
      published_answer # category => public content, translated in the primary locale

      # other_category => internal content translated ONLY to the alternative locale
      create(:knowledge_base_answer, :internal, category: other_category, translation_attributes: { kb_locale: alternative_locale })
    end

    context 'with a reader browsing the primary locale' do
      let(:user) { reader }

      it 'hides the category whose content is untranslated', :aggregate_failures do
        expect(subcategory_ids).to include(category.id)
        expect(subcategory_ids).not_to include(other_category.id)
      end
    end

    context 'with a reader browsing the alternative locale' do
      let(:user)   { reader }
      let(:locale) { alternative_locale }

      it 'shows the category in the locale its content is translated to' do
        expect(subcategory_ids).to include(other_category.id)
      end
    end

    context 'with an editor browsing the primary locale' do
      let(:user) { editor }

      it 'still shows the category, color-coded as draft in this locale', :aggregate_failures do
        expect(details_of(other_category)).to include(visibility: :draft)
        # The untranslated answer is still browsable for editors, so it is counted.
        expect(details_of(other_category)).to include(answer_count: 1)
      end
    end

    context 'with an editor browsing the alternative locale' do
      let(:user)   { editor }
      let(:locale) { alternative_locale }

      it 'color-codes the category by its content visibility in that locale' do
        expect(details_of(other_category)).to include(visibility: :internal)
      end
    end
  end
end
