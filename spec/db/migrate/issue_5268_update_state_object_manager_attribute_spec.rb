# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue5268UpdateStateObjectManagerAttribute, type: :db_migration do
  context 'when the ticket state attribute has inactive states in filter values', db_strategy: :reset do
    let(:inactive_state)  { create(:ticket_state, state_type: Ticket::StateType.find_by(name: 'closed'), active: false) }
    let(:state_attribute) { ObjectManager::Attribute.get(name: 'state_id', object: 'Ticket') }

    before do
      inactive_state

      # Purposefully include inactive state in the object manager attribute options.
      state_attribute.data_option[:filter] = Ticket::State.by_category_ids(:viewable)
      state_attribute.screens[:create_middle][:'ticket.agent'][:filter] = Ticket::State.by_category_ids(:viewable_agent_new)
      state_attribute.screens[:create_middle][:'ticket.customer'][:filter] = Ticket::State.by_category_ids(:viewable_customer_new)
      state_attribute.screens[:edit][:'ticket.agent'][:filter] = Ticket::State.by_category_ids(:viewable_agent_edit)
      state_attribute.screens[:edit][:'ticket.customer'][:filter] = Ticket::State.by_category_ids(:viewable_customer_edit)
      state_attribute.screens[:overview_bulk][:'ticket.agent'][:filter] = Ticket::State.by_category_ids(:viewable_agent_edit)
      state_attribute.save!
    end

    it 'updates filter values to not include the inactive state' do
      expect { migrate }
        .to change  { state_attribute.reload.data_option[:filter] }.from(include(inactive_state.id)).to(not_include(inactive_state.id))
        .and change { state_attribute.reload.screens[:create_middle][:'ticket.agent'][:filter] }.from(include(inactive_state.id)).to(not_include(inactive_state.id))
        .and change { state_attribute.reload.screens[:create_middle][:'ticket.customer'][:filter] }.from(include(inactive_state.id)).to(not_include(inactive_state.id))
        .and change { state_attribute.reload.screens[:edit][:'ticket.agent'][:filter] }.from(include(inactive_state.id)).to(not_include(inactive_state.id))
        .and change { state_attribute.reload.screens[:edit][:'ticket.customer'][:filter] }.from(include(inactive_state.id)).to(not_include(inactive_state.id))
        .and change { state_attribute.reload.screens[:overview_bulk][:'ticket.agent'][:filter] }.from(include(inactive_state.id)).to(not_include(inactive_state.id))
    end
  end
end
