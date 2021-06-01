# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ::Sequencer::Sequence::Import::Freshdesk::TicketField, sequencer: :sequence do

  context 'when trying to import ticket fields from Freshdesk', db_strategy: :reset do

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
        id_map:     {},
      }
    end

    let(:base_resource) do
      {
        'id'                     => 80_000_561_223,
        'label'                  => 'My custom field',
        'description'            => nil,
        'position'               => 14,
        'required_for_closure'   => false,
        'required_for_agents'    => false,
        'default'                => false,
        'customers_can_edit'     => true,
        'label_for_customers'    => 'custom_dropdown',
        'required_for_customers' => false,
        'displayed_to_customers' => true,
        'created_at'             => '2021-04-12T20:48:40Z',
        'updated_at'             => '2021-04-12T20:48:40Z',
      }
    end

    context 'when field is a dropdown' do
      let(:resource) do
        base_resource.merge(
          {
            'name'    => 'cf_custom_dropdown',
            'type'    => 'custom_dropdown',
            'choices' => %w[key1 key2],
          }
        )
      end

      it 'adds a custom field' do
        p resource
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_dropdown'])
      end
    end

    context 'when field is a decimal' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_integer',
            'type' => 'custom_decimal',
          }
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_integer'])
      end
    end

    context 'when field is a number' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_integer',
            'type' => 'custom_number',
          }
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_integer'])
      end
    end

    context 'when field is a date' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_date',
            'type' => 'custom_date',
          }
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_date'])
      end
    end

    context 'when field is a checkbox' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_checkbox',
            'type' => 'custom_checkbox',
          }
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_checkbox'])
      end
    end

    context 'when field is a text' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_text',
            'type' => 'custom_text',
          }
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_text'])
      end
    end

    context 'when field is a paragraph' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_paragraph',
            'type' => 'custom_paragraph',
          }
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_paragraph'])
      end
    end

    context 'when field is invalid' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_unknown',
            'type' => 'custom_unknown',
          }
        )
      end

      it 'raises an error' do
        expect { process(process_payload) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
