# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The rules around a stored order — which modes accept one, and that it has to be complete — are the
#   same as for categories and are covered once, in
#   spec/services/service/knowledge_base/reorder/categories_spec.rb (both services share
#   Service::KnowledgeBase::Reorder::Base). This covers what is this service's own: the
#   scope it numbers, and the category it writes the mode to.
RSpec.describe Service::KnowledgeBase::Reorder::Answers do
  subject(:execute) do
    described_class.with_current_user(user).execute(**arguments)
  end

  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)        { create(:user, roles: [editor_role]) }

  let(:record)       { category }
  let(:sorting_mode) { nil }
  let(:ordered_ids)  { nil }
  let(:arguments)    { { category: record, sorting_mode:, ordered_ids: }.compact }

  before { knowledge_base }

  describe 'the sorting mode' do
    let(:sorting_mode) { 'alphabetical' }

    it 'stores it on the category the answers are in' do
      expect { execute }.to change { category.reload.answer_sorting_mode }.from('manual').to('alphabetical')
    end

    # A category holds a mode per list, so ordering its answers says nothing about the order its
    #   subcategories are listed in — the combination a single column could not express.
    it 'leaves the subcategories of that category alone', :aggregate_failures do
      subcategory

      expect { execute }.not_to change { category.reload.category_sorting_mode }
      expect(category.reload.answer_sorting_mode).to eq('alphabetical')
    end

    it 'leaves the knowledge base alone' do
      expect { execute }.not_to change { knowledge_base.reload.category_sorting_mode }
    end
  end

  describe 'the hand-made order' do
    let(:first)  { create(:knowledge_base_answer, category:, position: 0) }
    let(:second) { create(:knowledge_base_answer, category:, position: 1) }
    let(:third)  { create(:knowledge_base_answer, category:, position: 2) }

    let(:sorting_mode) { 'manual' }
    let(:ordered_ids)  { [third.id, first.id, second.id] }

    before { first && second && third }

    def positions
      [first, second, third].map { |record| record.reload.position }
    end

    it 'writes the submitted order as positions, counted from zero' do
      execute

      expect(positions).to eq([1, 2, 0])
    end

    it 'returns the category rather than the reordered answers' do
      expect(execute).to eq(category)
    end

    # `acts_as_list` is scoped to `category`, so each category numbers its own answers.
    it 'leaves the answers of another category alone' do
      other = create(:knowledge_base_answer, category: other_category, position: 7)

      execute

      expect(other.reload.position).to eq(7)
    end

    # Every answer of the category counts, whatever it is published as — the editor rearranging them
    #   sees them all.
    context 'with an unpublished answer among them' do
      let(:second) { create(:knowledge_base_answer, :internal, category:, position: 1) }

      it 'numbers it like the others' do
        execute

        expect(positions).to eq([1, 2, 0])
      end
    end

    context 'when a submitted id is a subcategory rather than an answer' do
      let(:ordered_ids) { [third.id, first.id, second.id, subcategory.id] }

      it 'is refused' do
        expect { execute }.to raise_error(Exceptions::UnprocessableContent, %r{all items in scope})
      end
    end
  end

  describe 'authorization' do
    let(:sorting_mode) { 'alphabetical' }

    context 'with a reader' do
      let(:user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

      it 'is refused' do
        expect { execute }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context 'with a granular editor of one subtree' do
      let(:granular_role) { create(:role, permission_names: 'knowledge_base.editor') }
      let(:user)          { create(:user, roles: [granular_role]) }

      before do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: category, role: granular_role, access: 'editor')
      end

      it 'is allowed in their own category' do
        expect(execute.answer_sorting_mode).to eq('alphabetical')
      end

      context 'with a category they only read' do
        let(:record) { other_category }

        it 'is refused' do
          expect { execute }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end

    context 'without a current user' do
      it 'is rejected' do
        expect { described_class.execute(**arguments) }.to raise_error(%r{Current user is required})
      end
    end
  end

  describe 'the knowledge base it writes to' do
    let(:sorting_mode) { 'alphabetical' }

    context 'when none is active' do
      before { knowledge_base.update!(active: false) }

      it 'is refused' do
        expect { execute }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
