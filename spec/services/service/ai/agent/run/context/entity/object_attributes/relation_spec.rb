# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Agent::Run::Context::Entity::ObjectAttributes::Relation, type: :service do
  let(:relation_context) { described_class.new(object_attribute: object_attribute, entity_value: entity_value) }

  describe '.applicable?' do
    context 'when relation is present' do
      let(:object_attribute) { build(:object_manager_attribute_select, data_option: { relation: 'Group' }) }

      it 'returns true' do
        expect(described_class.applicable?(object_attribute)).to be true
      end
    end

    context 'when relation is not present' do
      let(:object_attribute) { build(:object_manager_attribute_text) }

      it 'returns false' do
        expect(described_class.applicable?(object_attribute)).to be false
      end
    end
  end

  describe '#prepare' do
    let(:group)            { create(:group, name: 'Test Group') }
    let(:object_attribute) { build(:object_manager_attribute_select, data_option: { relation: 'Group' }) }
    let(:entity_value)     { group.id }

    context 'when entity value exists' do
      it 'returns the value and label for the specific entity' do
        group # create the group
        result = relation_context.prepare

        expect(result).to eq({
                               value: group.id,
                               label: 'Test Group'
                             })
      end
    end

    context 'when entity value does not exist' do
      let(:entity_value) { 99_999 }

      it 'returns nil' do
        result = relation_context.prepare

        expect(result).to be_nil
      end
    end

    context 'when entity value is blank' do
      let(:entity_value) { nil }

      it 'returns nil' do
        result = relation_context.prepare

        expect(result).to be_nil
      end
    end

    context 'with mapped relations' do
      let(:ticket_state) { create(:ticket_state, name: 'Another state') }
      let(:object_attribute) { build(:object_manager_attribute_select, data_option: { relation: 'TicketState' }) }
      let(:entity_value)     { ticket_state.id }

      it 'uses the mapped relation name' do
        ticket_state # create the state
        result = relation_context.prepare

        expect(result).to eq({
                               value: ticket_state.id,
                               label: 'Another state'
                             })
      end
    end
  end
end
