# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe FormSchema::FieldResolver do
  context 'when resolving fields for ObjectManager attributes' do
    let(:context)          { Struct.new(:current_user, :current_user?).new(User.find(1)) }
    let(:schema)           { described_class.field_for_object_attribute(context: context, attribute: object_attribute).schema }
    let(:object_attribute) { ObjectManager::Attribute.add(object: 'Ticket', created_by_id: 1, updated_by_id: 1, **object_attribute_data) }

    shared_examples 'field resolver' do
      it 'resolves correctly' do
        expect(schema).to eq(expected_schema)
      end
    end

    context 'with field type text' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'input',
          data_option: {
            type:      'text',
            maxlength: 60,
            default:   'initial value'
          },
        }
      end
      let(:expected_schema) do
        {
          type:  'text',
          name:  'my_field',
          label: 'My Field',
          value: 'initial value',
          props: { maxlength: 60 }
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type password' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'input',
          data_option: { type: 'password', maxlength: 60, },
        }
      end
      let(:expected_schema) do
        {
          type:  'password',
          name:  'my_field',
          label: 'My Field',
          props: { maxlength: 60 }
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type email' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'input',
          data_option: { type: 'email', maxlength: 60 },
        }
      end
      let(:expected_schema) do
        {
          type:  'email',
          name:  'my_field',
          label: 'My Field',
          props: {}
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type textarea' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'textarea',
          data_option: { maxlength: 60, },
        }
      end
      let(:expected_schema) do
        {
          type:  'textarea',
          name:  'my_field',
          label: 'My Field',
          props: { maxlength: 60 }
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type richtext' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'richtext',
          data_option: { maxlength: 500 },
        }
      end
      let(:expected_schema) do
        {
          type:  'editor',
          name:  'my_field',
          label: 'My Field',
          props: {}
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type boolean' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'boolean',
          data_option: {
            options: {
              true  => 'ja',
              false => 'nein',
            },
            default: false,
          },
        }
      end
      let(:expected_schema) do
        {
          type:  'select',
          name:  'my_field',
          label: 'My Field',
          value: false,
          props: {
            options: [
              { value: true, label: 'ja' },
              { value: false, label: 'nein' },
            ],
          }
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type select - custom sort' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'select',
          data_option: {
            options: [
              { value: 'val1', name: 'name1' },
              { value: 'val2', name: 'name2' },
            ],
            default: 'val2',
          },
        }
      end
      let(:expected_schema) do
        {
          type:  'select',
          name:  'my_field',
          label: 'My Field',
          value: 'val2',
          props: {
            options: [
              { value: 'val1', label: 'name1' },
              { value: 'val2', label: 'name2' },
            ],
          }
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type select - default sort' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'select',
          data_option: {
            options: { val1: 'name1', val2: 'name2' },
            default: 'val1',
          },
        }
      end
      let(:expected_schema) do
        {
          type:  'select',
          name:  'my_field',
          label: 'My Field',
          value: 'val1',
          props: {
            options: [
              { value: 'val1', label: 'name1' },
              { value: 'val2', label: 'name2' },
            ],
          }
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type multiselect - custom sort' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'multiselect',
          data_option: {
            options: [
              { value: 'val1', name: 'name1' },
              { value: 'val2', name: 'name2' },
            ],
            default: 'val2',
          },
        }
      end
      let(:expected_schema) do
        {
          type:  'select',
          name:  'my_field',
          label: 'My Field',
          value: 'val2',
          props: {
            options:  [
              { value: 'val1', label: 'name1' },
              { value: 'val2', label: 'name2' },
            ],
            multiple: true,
          }
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type multiselect - default sort' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'multiselect',
          data_option: {
            options: { val1: 'name1', val2: 'name2' },
            default: 'val1',
          },
        }
      end
      let(:expected_schema) do
        {
          type:  'select',
          name:  'my_field',
          label: 'My Field',
          value: 'val1',
          props: {
            options:  [
              { value: 'val1', label: 'name1' },
              { value: 'val2', label: 'name2' },
            ],
            multiple: true,
          }
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type integer' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'integer',
          data_option: {
            default: 20,
            min:     0,
            max:     100,
          },
        }
      end
      let(:expected_schema) do
        {
          type:  'number',
          name:  'my_field',
          label: 'My Field',
          value: 20,
          props: {
            min: 0,
            max: 100,
          }
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type date' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'date',
          data_option: {
            diff: 2,
          }
        }
      end
      let(:expected_schema) do
        {
          type:  'date',
          name:  'my_field',
          label: 'My Field',
          props: {},
        }
      end

      include_examples 'field resolver'
    end

    context 'with field type datetime' do
      let(:object_attribute_data) do
        {
          name:        'my_field',
          display:     'My Field',
          data_type:   'datetime',
          data_option: {
            diff:   2,
            future: true,
            past:   false,
          }
        }
      end
      let(:expected_schema) do
        {
          type:  'datetime',
          name:  'my_field',
          label: 'My Field',
          props: {},
        }
      end

      include_examples 'field resolver'
    end

  end
end
