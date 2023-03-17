# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'ChecksCoreWorkflow' do

  let(:agent_group) { create(:group) }
  let(:agent)       { create(:agent, groups: [agent_group]) }

  before do
    UserInfo.current_user_id = agent.id
  end

  context 'when creation of closed tickets are only allowed by type set' do
    subject(:ticket) { create(:ticket, group: agent_group, screen: 'create_middle', state: Ticket::State.find_by(name: 'open'), pending_time: 5.days.from_now) }

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.state_id': {
                 operator:     'set_fixed_to',
                 set_fixed_to: [ Ticket::State.find_by(name: 'closed').id.to_s ]
               },
             })
    end

    it 'checks that workflow blocked creation' do
      expect { ticket }.to raise_error(Exceptions::UnprocessableEntity, "Invalid value '#{Ticket::State.find_by(name: 'open').id}' for field 'state_id'!")
    end
  end

  context 'when creation of closed tickets are only allowed by type remove' do
    subject(:ticket) { create(:ticket, group: agent_group, screen: 'create_middle', state: Ticket::State.find_by(name: 'open'), pending_time: 5.days.from_now) }

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.state_id': {
                 operator:      'remove_option',
                 remove_option: [ Ticket::State.find_by(name: 'open').id.to_s ]
               },
             })
    end

    it 'checks that workflow blocked creation' do
      expect { ticket }.to raise_error(Exceptions::UnprocessableEntity, "Invalid value '#{Ticket::State.find_by(name: 'open').id}' for field 'state_id'!")
    end
  end

  context 'when creation of closed tickets are only allowed by type add' do
    subject(:ticket) { create(:ticket, group: agent_group, screen: 'create_middle', state: Ticket::State.find_by(name: 'open'), pending_time: 5.days.from_now) }

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.state_id': {
                 operator:      'remove_option',
                 remove_option: [ Ticket::State.find_by(name: 'open').id.to_s ]
               },
             })
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.state_id': {
                 operator:   'add_option',
                 add_option: [ Ticket::State.find_by(name: 'open').id.to_s ]
               },
             })
    end

    it 'checks ticket creation success' do
      expect { ticket }.not_to raise_error
    end
  end

  context 'when pending time on pending ticket' do
    subject(:ticket) { create(:ticket, group: agent_group, screen: 'create_middle', state: Ticket::State.find_by(name: 'pending reminder')) }

    it 'checks that the pending time is mandatory' do
      expect { ticket }.to raise_error(Exceptions::UnprocessableEntity, "Missing required value for field 'pending_time'!")
    end
  end

  context 'when creation of mandatory field but hidden' do
    subject(:ticket) { create(:ticket, group: agent_group, screen: 'create_middle', state: Ticket::State.find_by(name: 'open')) }

    before do
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.pending_time': {
                 operator:      'set_mandatory',
                 set_mandatory: true
               },
             })
      create(:core_workflow,
             object:  'Ticket',
             perform: {
               'ticket.pending_time': {
                 operator: 'hide',
                 hide:     true
               },
             })
    end

    it 'does create a ticket without pending_time value' do
      expect { ticket }.not_to raise_error
    end
  end

  describe 'Tickets can be closed with the bulk action, even when a mandatory field is empty #4198', db_strategy: :reset do
    let(:ticket) { create(:ticket, group: agent_group, state: Ticket::State.find_by(name: 'open')) }
    let(:ticket2)       { create(:ticket, group: agent_group, state: Ticket::State.find_by(name: 'open')) }
    let(:field_name)    { SecureRandom.uuid }
    let(:ticket_update) { { screen: 'edit', title: 'test' } }

    before do
      ticket

      create(:object_manager_attribute_text, object_name: 'Ticket', name: field_name, display: field_name, screens: {
               'edit' => {
                 'ticket.agent' => {
                   shown:    true,
                   required: false,
                 }
               }
             })
      ObjectManager::Attribute.migration_execute

      ticket2

      create(:core_workflow,
             object:  'Ticket',
             perform: {
               "ticket.#{field_name}": {
                 operator:      'set_mandatory',
                 set_mandatory: true
               },
             })
    end

    it 'does raise error for old tickets before required test field got created' do
      expect do
        ticket.update(ticket_update)
      end.to raise_error(Exceptions::ApplicationModel, "Missing required value for field '#{field_name}'!")
    end

    it 'does raise error for new tickets after required test field got created' do
      expect do
        ticket2.update(ticket_update)
      end.to raise_error(Exceptions::ApplicationModel, "Missing required value for field '#{field_name}'!")
    end
  end
end
