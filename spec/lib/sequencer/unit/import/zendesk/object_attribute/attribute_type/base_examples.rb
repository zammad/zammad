# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.shared_examples Sequencer::Unit::Import::Zendesk::ObjectAttribute::AttributeType::Base do
  let(:object_attribute_type) { 'input' }
  let(:object_attribute_data_option) do
    {
      null:      false,
      note:      'Example attribute description',
      type:      'text',
      maxlength: 255,
    }
  end

  let(:zendesk_object_field_type) { object_attribute_type }
  let(:zendesk_object_base_field_attributes) do
    {
      title:                'Example attribute',
      description:          'Example attribute description',
      removable:            false,
      active:               true,
      position:             12,
      visible_in_portal:    true,
      required_in_portal:   true,
      required:             true,
      type:                 zendesk_object_field_type,
      custom_field_options: [],
    }
  end

  let(:zendesk_object_field_attributes) do
    {
      regexp_for_validation: '',
    }
  end

  let(:attribute) do
    ZendeskAPI::TicketField.new(
      nil,
      zendesk_object_base_field_attributes.merge(zendesk_object_field_attributes)
    )
  end

  let(:expected_structure) do
    {
      object:        'Ticket',
      name:          'example_field',
      display:       'Example attribute',
      data_type:     object_attribute_type,
      data_option:   object_attribute_data_option,
      editable:      true,
      active:        true,
      screens:       {
        edit: {
          Customer: {
            shown: true,
            null:  false
          },
          view:     {
            '-all-' => {
              shown: true
            }
          }
        }
      },
      position:      12,
      created_by_id: 1,
      updated_by_id: 1
    }
  end

  describe 'exception handling' do
    let(:error_text) { Faker::Lorem.sentence }

    it 'extends ObjectManager Attribute exception message' do
      allow(ObjectManager::Attribute).to receive(:add).and_raise(RuntimeError, error_text)

      expect do
        described_class.new('Ticket', 'example_field', attribute)
      end.to raise_error(RuntimeError, %r{'example_field': #{error_text}$})
    end
  end

  describe 'argument handling' do
    before do
      allow(ObjectManager::Attribute).to receive(:add).with(hash_including(object: 'Ticket'))
    end

    it 'takes an ObjectLookup name as the first argument' do
      described_class.new('Ticket', 'example_field', attribute)
      expect(ObjectManager::Attribute).to have_received(:add)
    end

    it 'accepts a constant ObjectLookup name' do
      described_class.new(Ticket, 'example_field', attribute)
      expect(ObjectManager::Attribute).to have_received(:add)
    end
  end

  context 'when migration is executed' do
    it 'imports object attribute from given zendesk object field' do
      allow(ObjectManager::Attribute).to receive(:add).with(expected_structure)
      allow(ObjectManager::Attribute).to receive(:migration_execute)

      described_class.new('Ticket', 'example_field', attribute)

      expect(ObjectManager::Attribute).to have_received(:migration_execute)
    end
  end
end
