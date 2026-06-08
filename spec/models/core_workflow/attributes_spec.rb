# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe CoreWorkflow::Attributes, type: :model do
  let!(:ticket) { create(:ticket, state: Ticket::State.find_by(name: 'pending reminder'), pending_time: 5.days.from_now) }
  let!(:base_payload) do
    {
      'event'      => 'core_workflow',
      'request_id' => 'default',
      'class_name' => 'Ticket',
      'screen'     => 'create_middle',
      'params'     => {
        'id'       => ticket.id,
        'state_id' => Ticket::State.find_by(name: 'open').id,
      },
    }
  end
  let(:payload) { base_payload }
  let!(:action_user) { create(:agent, groups: [ticket.group]) }
  let(:result)       { described_class.new(result_object: CoreWorkflow::Result.new(payload: payload, user: action_user)) }

  describe '#payload_class' do
    it 'returns class' do
      expect(result.payload_class).to eq(Ticket)
    end
  end

  describe '#selected_only' do
    it 'returns state open' do
      expect(result.selected_only.state.name).to eq('open')
    end
  end

  describe '#selected' do
    it 'returns state open' do
      expect(result.selected.state.name).to eq('open')
    end
  end

  describe '#saved_only' do
    it 'returns state pending reminder' do
      expect(result.saved_only.state.name).to eq('pending reminder')
    end
  end

  describe '#saved' do
    it 'returns state pending reminder' do
      expect(result.saved.state.name).to eq('pending reminder')
    end
  end

  describe '#mandatory_default' do
    it 'priority should be mandatory by default' do
      expect(result.mandatory_default['priority_id']).to be true
    end
  end

  describe '#visibility_default' do
    it 'priority should be shown by default' do
      expect(result.visibility_default['priority_id']).to eq('show')
    end
  end

  describe '#options_array' do
    it 'does not include disabled options' do
      expect(result.options_array(
               [
                 {
                   'value'    => '1',
                   'disabled' => true,
                 },
                 {
                   'value' => '2',
                 }
               ],
               'example'
             ))
        .to eq(['2'])
    end
  end

  describe 'restrict_values_default', aggregate_failures: true do
    context 'with a tree_select attribute which has disabled options', db_strategy: :reset do
      let(:field_name) { SecureRandom.uuid }
      let(:attribute) do
        create(:object_manager_attribute_tree_select, data_option: {
                 'options' => [
                   {
                     'name'     => 'Incident',
                     'value'    => 'Incident',
                     'children' => [
                       {
                         'disabled' => true,
                         'value'    => 'Incident::Hardware',
                         'children' => [
                           {
                             'name'  => 'Monitor',
                             'value' => 'Incident::Hardware::Monitor'
                           },
                           {
                             'name'  => 'Mouse',
                             'value' => 'Incident::Hardware::Mouse'
                           },
                           {
                             'name'  => 'Keyboard',
                             'value' => 'Incident::Hardware::Keyboard'
                           }
                         ]
                       },
                     ]
                   },
                   {
                     'name'  => 'Change request',
                     'value' => 'Change request'
                   }
                 ],
                 default: '',
               }, name: field_name)
      end

      before do
        attribute

        ObjectManager::Attribute.migration_execute
      end

      it 'excludes disabled values' do
        values = result.restrict_values_default[field_name]

        expect(values)
          .to include('Incident::Hardware::Mouse', 'Incident::Hardware::Keyboard', 'Change request')
          .and not_include('Incident::Hardware')
      end
    end
  end
end
