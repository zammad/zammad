# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::AI::Agent::Run::Context::Instruction::ObjectAttributes::Options, type: :service do
  let(:filter_values)   { {} }
  let(:options_context) { described_class.new(object_attribute: object_attribute, filter_values: filter_values) }

  describe '#prepare_for_instruction' do
    context 'with array options (tree_select) with disabled options' do
      let(:object_attribute) do
        build(:object_manager_attribute_tree_select, data_option: {
                'options' => [
                  {
                    'name'     => 'Incident',
                    'value'    => 'Incident',
                    'children' => [
                      {
                        'name'     => 'Hardware',
                        'value'    => 'Incident::Hardware',
                        'disabled' => true,
                        'children' => [
                          {
                            'name'  => 'Monitor',
                            'value' => 'Incident::Hardware::Monitor',
                          },
                          {
                            'name'  => 'Mouse',
                            'value' => 'Incident::Hardware::Mouse',
                          },
                        ],
                      },
                    ],
                  },
                  {
                    'name'  => 'Change Request',
                    'value' => 'Change Request',
                  },
                ],
              })
      end

      it 'excludes disabled options but includes their non-disabled children' do
        result = options_context.prepare_for_instruction

        expect(result.pluck(:value)).to contain_exactly('Incident', 'Incident::Hardware::Monitor', 'Incident::Hardware::Mouse', 'Change Request')
      end

      context 'with filter values matching a disabled option' do
        let(:filter_values) { { 'Incident::Hardware' => 'hw desc', 'Incident::Hardware::Monitor' => 'monitor desc' } }

        it 'excludes disabled options even if they match filter values' do
          result = options_context.prepare_for_instruction

          expect(result.pluck(:value)).to contain_exactly('Incident::Hardware::Monitor')
        end
      end
    end
  end
end
