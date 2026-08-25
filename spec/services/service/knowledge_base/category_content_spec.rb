# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::CategoryContent do
  subject(:content) do
    described_class.with_current_user(user).execute(knowledge_base:, category: opened_category, locale:)
  end

  include_context 'basic Knowledge Base'

  let(:user)            { create(:admin) }
  let(:opened_category) { nil }
  let(:locale)          { primary_locale }

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
    #   not see. A draft answer is exactly that case for a reader — it is not counted in
    #   `direct_answer_count`, yet it still blocks the delete.
    context 'with an answer the current user cannot see' do
      before { draft_answer }

      it 'reports the category as not deletable', :aggregate_failures do
        expect(details_of(category)).to include(deletable: false)
        expect(details_of(category)).to include(direct_answer_count: 0)
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

  describe 'titles' do
    before { published_answer }

    it 'resolves the title of the browsed locale' do
      expect(content[:category_titles][category.id]).to eq(category.translation_primary.title)
    end

    # Content only counts in a locale it is translated to, but a title falls back — so a category
    #   can be shown with a title from another locale, flagged as missing its own.
    context 'with a locale the title is not translated to' do
      let(:locale) { alternative_locale }

      it 'falls back to the primary title' do
        expect(content[:category_titles][category.id]).to eq(category.translation_primary.title)
      end

      it 'flags the missing translation' do
        expect(content[:category_translation_missing][category.id]).to be(true)
      end

      context 'when the title is translated there' do
        before { create(:knowledge_base_category_translation, category:, kb_locale: alternative_locale) }

        it 'does not flag it' do
          expect(content[:category_translation_missing][category.id]).to be(false)
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
