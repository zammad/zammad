# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/checks_kb_client_notification_examples'
require 'models/concerns/has_translations_examples'
require 'models/contexts/factory_context'

RSpec.describe KnowledgeBase::Category, current_user_id: 1, type: :model do
  subject(:kb_category) { create(:knowledge_base_category) }

  include_context 'factory'

  it_behaves_like 'ChecksKbClientNotification'

  it { is_expected.to validate_presence_of(:category_icon) }
  it { is_expected.not_to validate_presence_of(:parent_id) }

  it { is_expected.to have_many(:answers) }
  it { is_expected.to have_many(:children) }
  it { is_expected.to have_many(:permissions) }
  it { is_expected.to belong_to(:parent).optional }
  it { is_expected.to belong_to(:knowledge_base) }

  context 'in multilevel tree' do
    subject(:kb_category_with_tree) { create(:kb_category_with_tree) }

    let(:knowledge_base)      { kb_category_with_tree.knowledge_base }
    let(:child_category)      { kb_category_with_tree.children.sorted.last }
    let(:grandchild_category) { child_category.children.sorted.first }

    it 'tests to fetch all categories in KB' do
      expect(knowledge_base.categories.count).to eq(7)
    end

    it 'fetches root categories' do
      expect(knowledge_base.categories.root).to contain_exactly(kb_category_with_tree)
    end

    it 'fetches direct children' do
      expect(kb_category_with_tree.children.count).to eq 2
    end

    it 'fetches all children' do
      expect(kb_category_with_tree.self_with_children.count).to eq 7
    end

    it 'fetches all parents' do
      expect(grandchild_category.self_with_parents.count).to eq 3
    end

    it 'root category has no parent' do
      expect(kb_category_with_tree.parent).to be_blank
    end

    it 'children category has to have a parent' do
      expect(child_category.parent).to be_present
    end

    context 'when fetching self with children' do
      it 'root category has multiple layers children and matches all KB categories' do
        expect(kb_category_with_tree.self_with_children).to match_array(knowledge_base.categories)
      end

      it 'child category has multiple layers of children' do
        expect(child_category.self_with_children.count).to eq 5
      end

      it 'grandchild category has single layer of children' do
        expect(grandchild_category.self_with_children.count).to eq 3
      end
    end

    context 'when fetching all children (excluding self)' do
      it 'root category does not include itself' do
        expect(kb_category_with_tree.all_children).not_to include(kb_category_with_tree)
      end

      it 'root category has all descendants matching self_with_children minus itself' do
        expect(kb_category_with_tree.all_children).to match_array(knowledge_base.categories - [kb_category_with_tree])
      end

      it 'grandchild category has one fewer entry than self_with_children (self excluded)' do
        expect(grandchild_category.all_children.count).to eq(grandchild_category.self_with_children.count - 1)
      end
    end

    context 'when fetching all knowledge base children' do
      # The CTE's cycle-guard path column doubles as ancestry information: an array of category
      # ids from root down to and including the row itself, flowing through on every row without
      # a custom SELECT (which would break aggregation such as `.count`).
      let(:categories_with_path) { knowledge_base.all_children.index_by(&:id) }

      it 'root category path is just itself' do
        expect(categories_with_path[kb_category_with_tree.id]['recursive_tree_path']).to eq([kb_category_with_tree.id])
      end

      it 'child category path is root then itself' do
        expect(categories_with_path[child_category.id]['recursive_tree_path']).to eq([kb_category_with_tree.id, child_category.id])
      end

      it 'grandchild category path is root, child, then itself' do
        expect(categories_with_path[grandchild_category.id]['recursive_tree_path']).to eq(
          [kb_category_with_tree.id, child_category.id, grandchild_category.id]
        )
      end

      it 'stays aggregatable since no custom SELECT is chained on' do
        expect(knowledge_base.all_children.count).to eq(knowledge_base.categories.count)
      end
    end

    context 'when fetchching self with children ids' do
      it 'root category has multiple layers children ids' do
        expect(kb_category_with_tree.self_with_children_ids).to match_array(knowledge_base.category_ids)
      end

      it 'child category has with multiple layers of children ids' do
        expect(child_category.self_with_children_ids.count).to eq 5
      end

      it 'grandchild category has single layer of children ids count' do
        expect(grandchild_category.self_with_children_ids.count).to eq 3
      end

      it 'grandchild category children ids matches direct children ids' do
        expect(grandchild_category.self_with_children_ids).to match_array([grandchild_category.id] + grandchild_category.child_ids)
      end
    end

    context 'when checking if item is a parent of' do
      it 'root category is indirect (and direct) parent of child' do
        expect(child_category).to be_self_parent(kb_category_with_tree)
      end

      it 'root category is indirect parent of grandchild' do
        expect(grandchild_category).to be_self_parent(kb_category_with_tree)
      end

      it 'child category is not a parent of root category' do
        expect(kb_category_with_tree).not_to be_self_parent(grandchild_category)
      end
    end

    context 'when parent_id contains a cycle (bypassing validations)' do
      # There is no DB constraint preventing a cycle in parent_id, only the
      # `cannot_be_child_of_parent` validation, which is bypassed here via `update_column` to
      # simulate e.g. a direct SQL update or a race condition. #self_with_children and
      # #self_with_parents must terminate safely (not hang or raise SystemStackError) thanks to
      # the `path` cycle guard in their recursive CTEs.
      #
      # This makes root a child of grandchild, closing a loop: root -> grandchild -> child -> root.
      before do
        kb_category_with_tree.update_column(:parent_id, grandchild_category.id)
      end

      it 'self_with_children terminates and still returns every reachable node exactly once' do
        expect(Timeout.timeout(5) { child_category.self_with_children.map(&:id) }).to match_array(knowledge_base.category_ids)
      end

      it 'self_with_parents terminates, stopping as soon as the cycle is closed' do
        expect(Timeout.timeout(5) { kb_category_with_tree.self_with_parents.map(&:id) }).to eq(
          [kb_category_with_tree.id, grandchild_category.id, child_category.id]
        )
      end

      it 'self_with_children_ids terminates and returns every reachable id exactly once' do
        # The per-level loop it used before this branch had no iteration bound, so a cycle made it
        # loop forever issuing one query per level.
        expect(Timeout.timeout(5) { child_category.self_with_children_ids }).to match_array(knowledge_base.category_ids)
      end

      it 'rejects attaching a new category beneath a cycle member instead of silently joining the corrupt component' do
        fresh = build(:knowledge_base_category, knowledge_base: knowledge_base, parent: child_category)

        expect(Timeout.timeout(5) { fresh.tap(&:valid?).errors[:parent_id] }).to include('is part of a circular reference')
      end

      it 'validating a cycle member itself reports errors instead of raising SystemStackError' do
        # `self_parent?` used to walk the parent chain with plain Ruby recursion, so validating any
        # category inside a cycle (even a save touching an unrelated attribute) crashed instead of
        # failing validation.
        expect(Timeout.timeout(5) { kb_category_with_tree.valid? }).to be(false)
      end
    end

    context 'when nesting beyond the allowed depth (psql)' do
      # Stub the limit down so a real 100-level tree is not needed; the arithmetic under test is
      # identical. The tree fixture itself reaches depth 3 (root -> child -> grandchild -> leaf),
      # so 4 is the lowest stub the fixture can be created under, making leaves the deepest
      # allowed level and grandchild_category the deepest valid parent target.
      before do
        allow(described_class).to receive(:max_depth).and_return(4)
      end

      let(:leaf)    { grandchild_category.children.sorted.first }
      let(:sibling) { kb_category_with_tree.children.sorted.first }

      it 'rejects creating a category below the deepest allowed level' do
        fresh = build(:knowledge_base_category, knowledge_base: knowledge_base)
        fresh.parent = leaf

        expect(fresh.tap(&:valid?).errors[:parent_id]).to include('would exceed the allowed nesting depth')
      end

      it 'allows creating a category at the deepest allowed level' do
        fresh = build(:knowledge_base_category, knowledge_base: knowledge_base)
        fresh.parent = grandchild_category

        expect(fresh.tap(&:valid?).errors[:parent_id]).to be_empty
      end

      it 'rejects moving a subtree whose descendants would end up beyond the limit' do
        # child_category itself would sit at depth 2, fine — but it carries a subtree two more
        # levels deep, whose leaves would land at depth 4, past the stubbed limit.
        child_category.parent = sibling

        expect(child_category.tap(&:valid?).errors[:parent_id]).to include("would push this category's children beyond the allowed nesting depth")
      end

      it 'still saves an unrelated change on an existing too-deep category' do
        # Data beyond the limit may pre-exist (imports, older versions); only parent changes are
        # policed, so such categories must not become read-only.
        deep_leaf = create(:knowledge_base_category, knowledge_base: knowledge_base).tap do |category|
          category.update_column(:parent_id, leaf.id)
        end

        expect(deep_leaf.reload.update(position: 5)).to be(true)
      end
    end

    context 'when parent_id references a deleted or nonexistent category' do
      # Validations must pass this case through untouched (no NoMethodError from walking a nil
      # parent association) so the save reaches the foreign-key constraint, which raises
      # ActiveRecord::InvalidForeignKey — the error controllers map to 422.
      let(:orphaned) do
        build(:knowledge_base_category, knowledge_base: knowledge_base).tap { |category| category.parent_id = 99_999_999 }
      end

      it 'does not raise during validation' do
        expect { orphaned.valid? }.not_to raise_error
      end

      it 'still hits the foreign-key constraint on save' do
        expect { orphaned.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
      end
    end
  end

  describe '#public_content?' do
    shared_examples 'verify visibility in given state' do |state:, is_visible:|
      it "returns #{is_visible} when contains #{state} answer" do
        object = create(:knowledge_base_category, "containing_#{state}")

        expect(object).send is_visible ? :to : :not_to, be_public_content(object.translations.first.kb_locale) # rubocop:disable RSpec/MissingExpectationTargetMethod
      end
    end

    include_examples 'verify visibility in given state', state: :published, is_visible: true
    include_examples 'verify visibility in given state', state: :internal,  is_visible: false
    include_examples 'verify visibility in given state', state: :draft,     is_visible: false
    include_examples 'verify visibility in given state', state: :archived,  is_visible: false
  end

  describe '#internal_content?' do
    shared_examples 'verify visibility in given state' do |state:, is_visible:|
      it "returns #{is_visible} when contains #{state} answer" do
        object = create(:knowledge_base_category, "containing_#{state}")

        expect(object).send is_visible ? :to : :not_to, be_internal_content(object.translations.first.kb_locale) # rubocop:disable RSpec/MissingExpectationTargetMethod
      end
    end

    include_examples 'verify visibility in given state', state: :published, is_visible: true
    include_examples 'verify visibility in given state', state: :internal,  is_visible: true
    include_examples 'verify visibility in given state', state: :draft,     is_visible: false
    include_examples 'verify visibility in given state', state: :archived,  is_visible: false
  end

  describe '#assets', current_user_id: -> { user.id } do
    subject(:assets) { another_category_answer && internal_answer && category.assets }

    include_context 'basic Knowledge Base'

    let(:user)                    { create(:agent) }
    let(:another_category)        { create(:knowledge_base_category, knowledge_base: knowledge_base) }
    let(:another_category_answer) { create(:knowledge_base_answer, :internal, category: another_category) }

    context 'without permissions' do
      it { expect(assets).to include_assets_of category }
    end

    context 'with readable another category' do
      before do
        KnowledgeBase::PermissionsUpdate
          .new(another_category)
          .update! user.roles.first => 'reader'
      end

      it { expect(assets).to include_assets_of category }
    end

    context 'with hidden another category' do
      before do
        KnowledgeBase::PermissionsUpdate
          .new(another_category)
          .update! user.roles.first => 'none'
      end

      it { expect(assets).to include_assets_of category }
      it { expect(assets).not_to include_assets_of another_category }

      context 'with published answer' do
        let(:another_category_published_answer) { create(:knowledge_base_answer, :published, category: another_category) }

        before { another_category_published_answer }

        it { expect(assets).to include_assets_of category }
      end
    end
  end

  describe '#attributes_with_association_ids' do
    context 'when category has children' do
      subject(:kb_category_with_tree) { create(:kb_category_with_tree) }

      it 'returns attributes with association ids' do
        expect(kb_category_with_tree.attributes_with_association_ids).to include(
          'child_ids' => kb_category_with_tree.child_ids,
        )
      end
    end
  end

  describe '.vector_indexable?' do
    subject(:kb_category_with_tree) { create(:kb_category_with_tree) }

    let(:sibling_category)    { kb_category_with_tree.children.sorted.first }
    let(:excluded_category)   { kb_category_with_tree.children.sorted.last }
    let(:child_category)      { excluded_category.children.sorted.first }
    let(:grandchild_category) { child_category.children.sorted.first }

    it 'indexes every category while nothing is excluded' do
      expect(described_class).to be_vector_indexable(excluded_category)
    end

    context 'when a category is excluded' do
      before { Setting.set('vectordb_knowledge_base_excluded_category_ids', [excluded_category.id]) }

      it 'excludes the category itself' do
        expect(described_class).not_to be_vector_indexable(excluded_category)
      end

      it 'excludes its sub-category' do
        expect(described_class).not_to be_vector_indexable(child_category)
      end

      it 'excludes a sub-category at any depth' do
        expect(described_class).not_to be_vector_indexable(grandchild_category)
      end

      it 'keeps the siblings of an excluded category indexable' do
        expect(described_class).to be_vector_indexable(sibling_category)
      end

      it 'keeps the parent of an excluded category indexable' do
        expect(described_class).to be_vector_indexable(kb_category_with_tree)
      end

      context 'when given an id instead of a category' do
        it 'excludes the category itself' do
          expect(described_class).not_to be_vector_indexable(excluded_category.id)
        end

        it 'excludes a sub-category at any depth' do
          expect(described_class).not_to be_vector_indexable(grandchild_category.id)
        end

        it 'accepts the id as a string' do
          expect(described_class).not_to be_vector_indexable(grandchild_category.id.to_s)
        end

        it 'keeps the siblings of an excluded category indexable' do
          expect(described_class).to be_vector_indexable(sibling_category.id)
        end

        it 'treats a missing category as indexable' do
          expect(described_class).to be_vector_indexable(nil)
        end
      end
    end

    context 'when the excluded ids are stored as strings' do
      before { Setting.set('vectordb_knowledge_base_excluded_category_ids', [excluded_category.id.to_s]) }

      it 'excludes the category itself' do
        expect(described_class).not_to be_vector_indexable(excluded_category)
      end

      it 'excludes a sub-category at any depth' do
        expect(described_class).not_to be_vector_indexable(grandchild_category)
      end
    end

    # The setting carries no validation and Setting.set takes a `validate: false` escape hatch, so
    # anything can end up stored there — and this is reached from an after_commit on every answer
    # save, where a raise used to take answer editing down with it.
    context 'when the stored setting value is unusable' do
      it 'reads a bare id as a single exclusion' do
        Setting.set('vectordb_knowledge_base_excluded_category_ids', excluded_category.id)

        expect(described_class).not_to be_vector_indexable(excluded_category)
      end

      it 'ignores entries that are not ids instead of coercing them' do
        Setting.set('vectordb_knowledge_base_excluded_category_ids', ["#{excluded_category.id}abc", ' ', nil])

        expect(described_class).to be_vector_indexable(excluded_category)
      end

      it 'does not let a zero-coercing entry exclude an unknown category' do
        Setting.set('vectordb_knowledge_base_excluded_category_ids', [nil, ' ', 0])

        expect(described_class).to be_vector_indexable(nil)
      end

      it 'survives a value that is not a list at all' do
        Setting.set('vectordb_knowledge_base_excluded_category_ids', 'nonsense')

        expect(described_class).to be_vector_indexable(excluded_category)
      end

      # Deleting an excluded category leaves its id behind in the setting. Both this check and
      # .vector_excluded_category_ids resolve the configured ids against the tree, so a dead id
      # simply drops out — and, being one list, they cannot disagree about it.
      it 'ignores an id that no longer resolves to a category' do
        kb_category_with_tree
        stale_id = described_class.maximum(:id) + 1
        Setting.set('vectordb_knowledge_base_excluded_category_ids', [stale_id])

        expect(described_class).to be_vector_indexable(stale_id)
      end
    end
  end

  describe '.vector_excluded_category_ids' do
    subject(:kb_category_with_tree) { create(:kb_category_with_tree) }

    let(:sibling_category)    { kb_category_with_tree.children.sorted.first }
    let(:excluded_category)   { kb_category_with_tree.children.sorted.last }
    let(:child_category)      { excluded_category.children.sorted.first }
    let(:grandchild_category) { child_category.children.sorted.first }

    it 'is empty while nothing is excluded' do
      kb_category_with_tree

      expect(described_class.vector_excluded_category_ids).to be_empty
    end

    context 'when a category is excluded' do
      before { Setting.set('vectordb_knowledge_base_excluded_category_ids', [excluded_category.id]) }

      it 'returns the category and its whole subtree' do
        expect(described_class.vector_excluded_category_ids)
          .to include(excluded_category.id, child_category.id, grandchild_category.id)
      end

      it 'leaves categories outside the subtree alone' do
        expect(described_class.vector_excluded_category_ids)
          .not_to include(kb_category_with_tree.id, sibling_category.id)
      end
    end

    # Excluding a category and something below it makes the two subtrees overlap.
    context 'when overlapping subtrees are excluded' do
      before { Setting.set('vectordb_knowledge_base_excluded_category_ids', [excluded_category.id, child_category.id]) }

      it 'returns each category once' do
        ids = described_class.vector_excluded_category_ids

        expect(ids).to eq(ids.uniq)
      end
    end
  end

  describe 'resyncing the vector index when a category moves', performs_jobs: true do
    subject(:kb_category_with_tree) { create(:kb_category_with_tree) }

    let(:knowledge_base)    { kb_category_with_tree.knowledge_base }
    let(:excluded_category) { kb_category_with_tree.children.sorted.last }
    let(:moved_category)    { create(:knowledge_base_category, knowledge_base:) }

    before do
      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
      Setting.set('vectordb_knowledge_base_excluded_category_ids', [excluded_category.id])
      moved_category
      clear_jobs
    end

    it 'resyncs when the category leaves an excluded parent' do
      moved_category.update!(parent: excluded_category)
      clear_jobs

      expect { moved_category.update!(parent: nil) }
        .to have_enqueued_job(VectorIndexKnowledgeBaseCategoryResyncJob).with(moved_category)
    end

    it 'resyncs when the category leaves a sub-category of an excluded parent' do
      moved_category.update!(parent: create(:knowledge_base_category, knowledge_base:, parent: excluded_category))
      clear_jobs

      expect { moved_category.update!(parent: nil) }
        .to have_enqueued_job(VectorIndexKnowledgeBaseCategoryResyncJob).with(moved_category)
    end

    # The documents stay in the index, but the search filters hits by category, so they cannot
    # surface — not worth fanning out over the subtree to remove them.
    it 'does not resync when the category moves under an excluded parent' do
      expect { moved_category.update!(parent: excluded_category) }
        .not_to have_enqueued_job(VectorIndexKnowledgeBaseCategoryResyncJob)
    end

    it 'does not resync when the category is excluded in its own right' do
      Setting.set('vectordb_knowledge_base_excluded_category_ids', [excluded_category.id, moved_category.id])
      moved_category.update!(parent: excluded_category)
      clear_jobs

      expect { moved_category.update!(parent: nil) }
        .not_to have_enqueued_job(VectorIndexKnowledgeBaseCategoryResyncJob)
    end

    it 'does not resync for a move between two indexable parents' do
      other_category = create(:knowledge_base_category, knowledge_base:)
      clear_jobs

      expect { moved_category.update!(parent: other_category) }
        .not_to have_enqueued_job(VectorIndexKnowledgeBaseCategoryResyncJob)
    end

    it 'does not resync for a change that leaves the parent alone' do
      expect { moved_category.update!(category_icon: 'f0c3') }
        .not_to have_enqueued_job(VectorIndexKnowledgeBaseCategoryResyncJob)
    end

    it 'does not resync when the vector database is unavailable' do
      moved_category.update!(parent: excluded_category)
      clear_jobs
      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(false)

      expect { moved_category.update!(parent: nil) }
        .not_to have_enqueued_job(VectorIndexKnowledgeBaseCategoryResyncJob)
    end
  end

  describe 'HasTranslations' do
    include_context 'basic Knowledge Base'

    let!(:record) { category }
    let(:add_translation) do
      ->(locale) { create(:knowledge_base_category_translation, category: record, kb_locale: locale) }
    end

    it_behaves_like 'HasTranslations'
  end
end
