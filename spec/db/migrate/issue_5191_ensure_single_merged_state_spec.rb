# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5191EnsureSingleMergedState, type: :db_migration do
  let(:merged_type)           { Ticket::StateType.find_by(name: 'merged') }
  let(:merged_states_by_name) { Ticket::State.where(name: 'merged') }
  let(:merged_states_by_type) { merged_type.states }

  def force_merged_state(&)
    Ticket::State.without_callback(:update, :before, :prevent_merged_state_editing, &)
  end

  def force_destroying_state(&)
    Ticket::State.without_callback(:destroy, :before, :prevent_merged_state_destruction, &)
  end

  context 'when single merged name state exists' do
    it 'keeps single state' do
      migrate

      expect(merged_states_by_type).to contain_exactly(merged_states_by_name.first)
    end
  end

  context 'when single merged type renamed state exists' do
    before do
      force_merged_state do
        obj = Ticket::State.find_by(name: 'merged')
        obj.name = 'other'
        obj.save! validate: false
      end
    end

    it 'renames state back' do
      migrate

      expect(merged_states_by_type).to contain_exactly(merged_states_by_name.first)
    end
  end

  context 'when additional merged type states exist' do
    let(:additional_state) { build(:ticket_state, state_type: merged_type).tap { it.save! validate: false } }

    before do
      force_merged_state do
        additional_state
      end
    end

    it 'changes additional states to closed type' do
      migrate

      expect(additional_state.reload.state_type.name).to eq('closed')
    end

    it 'keeps single merged state' do
      migrate

      expect(merged_states_by_type).to contain_exactly(merged_states_by_name.first)
    end
  end

  context 'when initial merged state was renamed and additional merged type states exist' do
    let(:additional_state) { build(:ticket_state, state_type: merged_type).tap { it.save! validate: false } }

    before do
      force_merged_state do
        obj = Ticket::State.find_by(name: 'merged')
        obj.name = 'other'
        obj.save! validate: false

        additional_state
      end
    end

    it 'renames oldest state back' do
      migrate

      expect(merged_states_by_name.first.id).to be < additional_state.id
    end

    it 'changes additional states to closed type' do
      migrate

      expect(additional_state.reload.state_type.name).to eq('closed')
    end

    it 'keeps single merged state' do
      migrate

      expect(merged_states_by_type).to contain_exactly(merged_states_by_name.first)
    end
  end

  context 'when multiple merged states exist and later state is named merged' do
    let(:additional_state) { build(:ticket_state, name: 'merged', state_type: merged_type).tap { it.save! validate: false } }
    let(:original_state) { Ticket::State.find_by(name: 'merged') }

    before do
      force_merged_state do
        original_state.name = 'other'
        original_state.save! validate: false

        additional_state
      end
    end

    it 'keeps new merged state named as merged' do
      migrate

      expect(additional_state.reload.state_type.name).to eq('merged')
    end

    it 'changes initial state to closed type' do
      migrate

      expect(original_state.reload.state_type.name).to eq('closed')
    end

    it 'keeps single merged state' do
      migrate

      expect(merged_states_by_type).to contain_exactly(merged_states_by_name.first)
    end
  end

  # https://github.com/zammad/zammad/issues/5544#issuecomment-2771512880
  context 'when no merged states exist' do
    before do
      force_destroying_state do
        merged_states_by_type.destroy_all
      end
    end

    it 'creates a new merged state' do
      migrate

      expect(merged_states_by_type.reload.first).to have_attributes(name: 'merged')
    end

    context 'when state named merged exists with a different type' do
      let(:state_type) { Ticket::StateType.lookup(name: 'open') }
      let(:merged_but_other_type) { create(:ticket_state, name: 'merged', state_type:) }

      prepend_before do
        merged_but_other_type
      end

      it 'creates a new merged state' do
        migrate

        expect(merged_states_by_type.reload.first).to have_attributes(name: 'merged')
      end

      it 'renames the old merged state' do
        migrate

        expect(merged_but_other_type.reload).to have_attributes(name: 'merged (open)')
      end
    end
  end
end
