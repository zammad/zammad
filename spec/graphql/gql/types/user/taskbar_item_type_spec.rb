# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::User::TaskbarItemType, :aggregate_failures do
  let(:user)  { create(:agent) }
  let(:owner) { user }
  let(:key) do
    entity = create(:ticket, owner: owner)

    "#{entity.class.name}-#{entity.id}"
  end
  let(:taskbar)  { create(:taskbar, user_id: user.id, key: key) }
  let(:instance) { described_class.send(:new, taskbar, Hashie::Mash.new({ current_user: user })) }

  describe 'field: entity' do

    context 'when entity is found and user has access' do
      it 'returns the entity as well as an appropriate access information' do
        expect(instance.entity).to be_a(Ticket)
        expect(instance.entity_access).to eq('Granted')
      end
    end

    context 'when entity is not found' do
      it 'returns nil as well as an appropriate access information' do
        taskbar.update!(key: 'Ticket-0')

        expect(instance.entity).to be_nil
        expect(instance.entity_access).to eq('NotFound')
      end
    end

    context 'when entity is found but user has no access' do
      let(:owner) { create(:agent) }

      it 'returns nil as well as an appropriate access information' do
        expect(instance.entity).to be_nil
        expect(instance.entity_access).to eq('Forbidden')
      end
    end

    context 'when entity is not instanciable' do
      it 'returns nil as well as an appropriate access information' do
        taskbar.update!(key: 'Unknown-0')

        expect(instance.entity).to be_nil
        expect(instance.entity_access).to be_nil
      end
    end

    context 'when entity is a ticket create screen' do
      let(:key) { 'TicketCreateScreen-4711' }

      it 'returns the state as entity' do
        taskbar.update!(state: { 'title' => 'Ticket Title', 'formSenderType' => 'email-out' })

        expect(instance.entity).to include('title' => 'Ticket Title', 'formSenderType' => 'email-out')
      end
    end
  end
end
