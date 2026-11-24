# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormUpdater::Relation do
  subject(:option_values) do
    relation_class.new(context: { current_user: }, current_user:, filter_ids:).options.pluck(:value)
  end

  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer) }
  let(:admin)    { create(:admin) }

  it 'requires every relation to declare the items the current user may see' do
    expect { described_class.new(context: {}, current_user: agent).send(:allowed_scope) }.to raise_error(RuntimeError, %r{needs to declare})
  end

  describe FormUpdater::Relation::Owner do
    let(:relation_class) { described_class }
    let(:other_agent)    { create(:agent) }
    let(:filter_ids)     { [other_agent.id, current_user.id] }

    context 'with an agent' do
      let(:current_user) { agent }

      it 'returns the requested users' do
        expect(option_values).to contain_exactly(other_agent.id, agent.id)
      end

      context 'when only some ids are requested' do
        let(:filter_ids) { [other_agent.id] }

        it 'returns no more than those' do
          expect(option_values).to eq([other_agent.id])
        end
      end
    end

    context 'with a customer' do
      let(:current_user) { customer }

      it 'returns no other user' do
        expect(option_values).to eq([customer.id])
      end
    end
  end

  describe FormUpdater::Relation::Group do
    let(:relation_class) { described_class }
    let(:customer_group) { create(:group) }
    let(:other_group)    { create(:group) }
    let(:filter_ids)     { [customer_group.id, other_group.id] }

    before { Setting.set('customer_ticket_create_group_ids', [customer_group.id]) }

    context 'with an agent' do
      let(:current_user) { agent }

      it 'returns the requested groups' do
        expect(option_values).to contain_exactly(customer_group.id, other_group.id)
      end
    end

    context 'with a customer' do
      let(:current_user) { customer }

      it 'returns no group outside of the customer groups' do
        expect(option_values).to eq([customer_group.id])
      end
    end
  end

  describe FormUpdater::Relation::Calendar do
    let(:relation_class) { described_class }
    let(:calendar)       { create(:calendar) }
    let(:filter_ids)     { [calendar.id] }

    context 'with an admin' do
      let(:current_user) { admin }

      it 'returns the requested calendars' do
        expect(option_values).to eq([calendar.id])
      end
    end

    context 'with an agent' do
      let(:current_user) { agent }

      it 'returns no calendar' do
        expect(option_values).to be_empty
      end
    end
  end

  describe FormUpdater::Relation::TicketState do
    let(:relation_class) { described_class }
    let(:filter_ids)     { [Ticket::State.find_by(name: 'new').id] }
    let(:current_user)   { customer }

    it 'returns the requested states' do
      expect(option_values).to eq(filter_ids)
    end
  end

  describe '#options_key', :aggregate_failures do
    def options_key(relation_class, filter_ids, **)
      relation_class.new(context: { current_user: agent }, current_user: agent, filter_ids:, **).options_key
    end

    it 'changes with the items and with one of them' do
      states = Ticket::State.where(name: %w[new open])
      key    = options_key(FormUpdater::Relation::TicketState, states.ids)

      expect(options_key(FormUpdater::Relation::TicketState, states.ids)).to eq(key)
      expect(options_key(FormUpdater::Relation::TicketState, [states.first.id])).not_to eq(key)
      expect(key.first).to eq('FormUpdater::Relation::TicketState')
      expect(options_key(FormUpdater::Relation::TicketPriority, Ticket::Priority.ids).first).to eq('FormUpdater::Relation::TicketPriority')

      travel 1.second
      states.first.update!(note: 'Changed.')
      expect(options_key(FormUpdater::Relation::TicketState, states.ids)).not_to eq(key)
    end

    it 'changes for owners with a name and the way names read, not with a login' do
      other = create(:agent)
      key   = options_key(FormUpdater::Relation::Owner, [other.id])

      travel 1.second
      other.update!(last_login: Time.zone.now)
      expect(options_key(FormUpdater::Relation::Owner, [other.id])).to eq(key)

      other.update!(lastname: 'Colleague')
      renamed = options_key(FormUpdater::Relation::Owner, [other.id])
      expect(renamed).not_to eq(key)

      Setting.set('user_name_format', 'last_first')
      expect(options_key(FormUpdater::Relation::Owner, [other.id])).not_to eq(renamed)
    end

    it 'names the format the owners read in, also where the setting changes after the key was read' do
      other    = create(:agent, firstname: 'Carla', lastname: 'Agent')
      relation = FormUpdater::Relation::Owner.new(context: { current_user: agent }, current_user: agent, filter_ids: [other.id])
      key      = relation.options_key

      Setting.set('user_name_format', 'last_first')

      expect(relation.options.pluck(:label)).to eq(['Carla Agent'])
      expect(relation.options_key).to eq(key)
      expect(options_key(FormUpdater::Relation::Owner, [other.id])).not_to eq(key)
    end

    it 'changes for an owner without a name with each of what stands for the name' do
      nameless = create(:agent, firstname: '', lastname: '', email: 'nameless@example.com', phone: '', mobile: '', login: 'nameless')

      keys = [{}, { email: '' }, { phone: '+49 30 123456' }, { phone: '', mobile: '+49 170 123456' }, { mobile: '', login: 'jdoe' }].map do |change|
        nameless.update!(change)

        options_key(FormUpdater::Relation::Owner, [nameless.id])
      end

      expect(keys.uniq.size).to eq(5)
    end
  end
end
