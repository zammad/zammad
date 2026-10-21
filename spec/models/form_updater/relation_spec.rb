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
end
