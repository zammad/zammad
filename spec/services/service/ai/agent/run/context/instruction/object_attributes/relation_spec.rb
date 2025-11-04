# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Agent::Run::Context::Instruction::ObjectAttributes::Relation, type: :service do
  let(:filter_values)    { {} }
  let(:relation_context) { described_class.new(object_attribute: object_attribute, filter_values: filter_values) }

  describe '.applicable?' do
    context 'when relation is present and allowed' do
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

    context 'when relation is not allowed' do
      let(:object_attribute) { build(:object_manager_attribute_select, data_option: { relation: 'InvalidRelation' }) }

      it 'returns false' do
        expect(described_class.applicable?(object_attribute)).to be false
      end
    end
  end

  describe '#prepare_for_instruction' do
    let(:group)            { create(:group, name: 'Test Group') }
    let(:object_attribute) { build(:object_manager_attribute_select, data_option: { relation: 'Group' }) }

    context 'when no filter values are provided' do
      it 'returns all active groups' do
        group # create the group
        result = relation_context.prepare_for_instruction

        expect(result).to include(
          value: group.id,
          label: 'Test Group'
        )
      end
    end

    context 'when filter values are provided' do
      let(:filter_values) { { group.id.to_s => 'Test group description' } }

      it 'returns only filtered groups with descriptions' do
        group # create the group
        result = relation_context.prepare_for_instruction

        expect(result).to eq([
                               {
                                 value:       group.id,
                                 label:       'Test Group',
                                 description: 'Test group description'
                               }
                             ])
      end
    end

    context 'when filter values are provided with integer keys' do
      let(:filter_values) { { group.id => 'Test group description' } }

      it 'returns only filtered groups with descriptions' do
        group # create the group
        result = relation_context.prepare_for_instruction

        expect(result).to eq([
                               {
                                 value:       group.id,
                                 label:       'Test Group',
                                 description: 'Test group description'
                               }
                             ])
      end
    end
  end
end
