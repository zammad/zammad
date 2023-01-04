# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Freshdesk::TicketField, sequencer: :sequence do

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

    context 'when field is a datetime' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_datetime',
            'type' => 'custom_date_time',
          }
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_datetime'])
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

    context 'when field is a phone number' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_phone_number',
            'type' => 'custom_phone_number',
          }
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_phone_number'])
      end

      it 'the custom field has type "tel"' do
        process(process_payload)
        expect(ObjectManager::Attribute.find_by(name: 'cf_custom_phone_number').data_option).to include('type' => 'tel')
      end
    end

    context 'when field is an URL' do
      let(:resource) do
        base_resource.merge(
          {
            'name' => 'cf_custom_url',
            'type' => 'custom_url',
          }
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['cf_custom_url'])
      end

      it 'the custom field has type "url"' do
        process(process_payload)
        expect(ObjectManager::Attribute.find_by(name: 'cf_custom_url').data_option).to include('type' => 'url')
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

      it 'ignore field' do
        expect { process(process_payload) }.to not_change(Ticket, :column_names)
      end
    end

    context 'when importing default fields' do
      let(:resource) do
        base_resource.merge(
          {
            'name'    => 'ticket_type',
            'label'   => 'Type',
            'type'    => 'default_ticket_type',
            'default' => true,
            'choices' => [
              'Question',
              'Incident',
              'Problem',
              'Feature Request',
              'Refunds and Returns',
              'Bulk orders',
              'Refund',
              'Request',
            ]
          }
        )
      end

      it "activate the already existing ticket 'type' field" do
        expect { process(process_payload) }.to change { ObjectManager::Attribute.get(object: 'Ticket', name: 'type').active }.from(false).to(true)
      end

      it "import the fixed option list for the ticket 'type' field" do
        process(process_payload)
        expect(ObjectManager::Attribute.get(object: 'Ticket', name: 'type').data_option[:options]).to include(resource['choices'].to_h { |choice| [choice, choice] })
      end
    end
  end
end
