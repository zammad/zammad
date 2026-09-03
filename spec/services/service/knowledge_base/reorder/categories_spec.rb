# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::Reorder::Categories do
  subject(:execute) do
    described_class.with_current_user(user).execute(**arguments)
  end

  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:user)        { create(:user, roles: [editor_role]) }

  let(:parent)       { nil }
  let(:sorting_mode) { nil }
  let(:ordered_ids)  { nil }
  let(:arguments)    { { parent:, sorting_mode:, ordered_ids: }.compact }

  before { knowledge_base }

  describe 'the sorting mode' do
    let(:sorting_mode) { 'alphabetical' }

    it 'stores it on the knowledge base for the top level' do
      expect { execute }.to change { knowledge_base.reload.category_sorting_mode }.from('manual').to('alphabetical')
    end

    context 'with a parent category' do
      let(:parent) { category }

      it 'stores it on that category' do
        expect { execute }.to change { category.reload.category_sorting_mode }.from('manual').to('alphabetical')
      end

      # The two lists of a category have a mode each, so ordering one says nothing about the other.
      it 'leaves the answers of that category alone' do
        expect { execute }.not_to change { category.reload.answer_sorting_mode }
      end

      it 'leaves the knowledge base alone' do
        expect { execute }.not_to change { knowledge_base.reload.category_sorting_mode }
      end
    end

    # Every mode a node can hold is one the schema offers, so the two lists cannot drift apart.
    KnowledgeBase::SORTING_MODES.each do |mode|
      context "with '#{mode}'" do
        let(:sorting_mode) { mode }
        # `manual` is never armed on its own, see 'the hand-made order' below.
        let(:ordered_ids)  { mode == 'manual' ? knowledge_base.categories.root.pluck(:id) : nil }

        it 'is accepted' do
          expect(execute.category_sorting_mode).to eq(mode)
        end
      end
    end

    # The picker sends what it shows, which is the stored mode until the editor picks another one.
    context 'when it is the stored one already' do
      let(:sorting_mode) { 'alphabetical' }

      before { knowledge_base.update!(category_sorting_mode: 'alphabetical') }

      it 'does not touch the record' do
        knowledge_base && category

        expect { execute }.not_to change { knowledge_base.reload.updated_at }
      end
    end

    context 'when it is omitted' do
      let(:sorting_mode) { nil }

      it 'leaves the stored mode alone' do
        knowledge_base.update!(category_sorting_mode: 'last_update')

        expect(execute.category_sorting_mode).to eq('last_update')
      end
    end
  end

  describe 'the hand-made order' do
    let(:first)  { create(:knowledge_base_category, knowledge_base:, position: 0) }
    let(:second) { create(:knowledge_base_category, knowledge_base:, position: 1) }
    let(:third)  { create(:knowledge_base_category, knowledge_base:, position: 2) }

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

    it 'returns the node rather than the reordered records' do
      expect(execute).to eq(knowledge_base)
    end

    context 'with subcategories of a category' do
      let(:parent) { category }
      let(:first)  { create(:knowledge_base_category, knowledge_base:, parent: category, position: 0) }
      let(:second) { create(:knowledge_base_category, knowledge_base:, parent: category, position: 1) }
      let(:third)  { create(:knowledge_base_category, knowledge_base:, parent: category, position: 2) }

      before { category.update!(category_sorting_mode: 'manual') }

      it 'writes the submitted order' do
        execute

        expect(positions).to eq([1, 2, 0])
      end

      # `acts_as_list` is scoped to `parent`, so the two lists are numbered apart from each other.
      it 'leaves the top level categories alone' do
        other = create(:knowledge_base_category, knowledge_base:, position: 7)

        execute

        expect(other.reload.position).to eq(7)
      end
    end

    # Arming the mode and rearranging in it are one call as much as two, so a client that has the
    #   order at hand may send both at once.
    context 'when the mode is armed in the same call' do
      before { knowledge_base.update!(category_sorting_mode: 'alphabetical') }

      it 'stores the order the mode it arms will read back', :aggregate_failures do
        execute

        expect(knowledge_base.reload.category_sorting_mode).to eq('manual')
        expect(positions).to eq([1, 2, 0])
      end
    end

    # A position is an index into one list; an automatic mode derives the order from the content
    #   itself and would never read it back.
    context 'when the node is not sorted manually' do
      let(:sorting_mode) { 'last_update' }

      it 'is refused' do
        expect { execute }.to raise_error(Exceptions::UnprocessableContent, %r{sorting mode is manual})
      end

      it 'stores no positions' do
        expect { execute }.to raise_error(Exceptions::UnprocessableContent)
          .and(not_change { positions })
      end
    end

    context 'when an id of the scope is missing' do
      let(:ordered_ids) { [third.id, first.id] }

      it 'is refused' do
        expect { execute }.to raise_error(Exceptions::UnprocessableContent, %r{all items in scope})
      end

      # The mode is written before the order is checked against the scope, so only the transaction
      #   around both keeps a refused call from arming a mode whose order never arrived. Asserted
      #   rather than left as a property that reads true today.
      #
      # Once here rather than in answers_spec.rb too: the transaction is
      #   Service::KnowledgeBase::Reorder::Base#execute's, the same one both services run in. The
      #   legacy endpoints have a guarantee of their own to assert, and do
      #   (spec/requests/knowledge_base/reorder_spec.rb).
      it 'stores neither the mode nor the order' do
        knowledge_base.update!(category_sorting_mode: 'alphabetical')

        expect { execute }.to raise_error(Exceptions::UnprocessableContent)
          .and(not_change { knowledge_base.reload.category_sorting_mode })
          .and(not_change { positions })
      end
    end

    context 'when an id is not part of the scope' do
      let(:ordered_ids) { [third.id, first.id, second.id, create(:knowledge_base_category, knowledge_base:, parent: category).id] }

      it 'is refused' do
        expect { execute }.to raise_error(Exceptions::UnprocessableContent, %r{all items in scope})
      end
    end

    # The whole list is renumbered, but only what actually moves is written: an untouched record
    #   would otherwise ping every open browse view for nothing.
    context 'when a record already sits at its index' do
      let(:ordered_ids) { [first.id, third.id, second.id] }

      it 'leaves it untouched' do
        first

        expect { execute }.not_to change { first.reload.updated_at }
      end
    end

    # The mirror of the refusal above: `manual` reads a stored order back, and the one it would read
    #   is whatever the list last held. Arming it means saying what the order is.
    context 'when it is omitted' do
      let(:ordered_ids) { nil }

      it 'is refused' do
        expect { execute }.to raise_error(Exceptions::UnprocessableContent, %r{all items in scope})
      end

      it 'stores neither the mode nor an order', :aggregate_failures do
        knowledge_base.update!(category_sorting_mode: 'alphabetical')

        expect { execute }.to raise_error(Exceptions::UnprocessableContent)
          .and(not_change { positions })
        expect(knowledge_base.reload.category_sorting_mode).to eq('alphabetical')
      end
    end

    # An automatic mode carries no order, and must not be made to look like it needs one.
    context 'when it is omitted with an automatic mode' do
      let(:sorting_mode) { 'last_update' }
      let(:ordered_ids)  { nil }

      it 'is accepted' do
        expect(execute.category_sorting_mode).to eq('last_update')
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

    # A granular editor of one subtree may rearrange that subtree, and nothing above it.
    context 'with a granular editor' do
      let(:granular_role) { create(:role, permission_names: 'knowledge_base.editor') }
      let(:user)          { create(:user, roles: [granular_role]) }

      before do
        create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
        create(:knowledge_base_permission, permissionable: category, role: granular_role, access: 'editor')
      end

      context 'with their own category' do
        let(:parent) { category }

        it 'is allowed' do
          expect(execute.category_sorting_mode).to eq('alphabetical')
        end
      end

      context 'with a category they only read' do
        let(:parent) { other_category }

        it 'is refused' do
          expect { execute }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context 'with the top level' do
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

  # The browse views refetch on the ping rather than on the payload, so the write has to fire one.
  describe 'the content update ping' do
    let(:sorting_mode) { 'alphabetical' }

    it 'notifies the subscribers' do
      allow(Gql::Subscriptions::KnowledgeBase::ContentUpdates).to receive(:trigger)

      execute

      expect(Gql::Subscriptions::KnowledgeBase::ContentUpdates).to have_received(:trigger)
    end
  end
end
