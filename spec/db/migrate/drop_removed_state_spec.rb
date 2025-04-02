# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe DropRemovedState, :aggregate_failures, db_strategy: :reset, type: :db_migration do

  context 'when removed state is absent' do
    it 'does not change anything' do
      expect { migrate }.not_to change(Ticket::State, :count)
    end
  end

  context 'when removed state is present' do

    let!(:state_type) { create(:ticket_state_type, name: 'removed') }
    let!(:state)      { create(:ticket_state, name: 'removed', state_type:) }

    context 'without tickets present' do
      before { migrate }

      it 'drops removed state and type' do
        expect { state.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { state_type.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with tickets present' do
      let!(:ticket) { create(:ticket, state:) }

      before { migrate }

      it 'keeps the ticket, the removed state and type' do
        expect(state.reload).to be_persisted
        expect(state_type.reload).to be_persisted
        expect(ticket.reload).to be_persisted
      end
    end
  end
end
