# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'zendesk_api'

RSpec.describe Sequencer::Sequence::Import::Zendesk::TicketField, sequencer: :sequence do

  context 'when trying to import ticket fields from Zendesk', db_strategy: :reset do

    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Zendesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
      }
    end

    let(:base_resource) do
      {
        'id'                    => 24_656_189,
        'raw_title'             => 'Custom Decimal',
        'description'           => 'A custom Decimal field',
        'raw_description'       => 'A custom Decimal field',
        'position'              => 7,
        'active'                => true,
        'required'              => true,
        'collapsed_for_agents'  => false,
        'regexp_for_validation' => '\\A[-+]?[0-9]*[.,]?[0-9]+\\z',
        'title_in_portal'       => 'Custom Decimal',
        'raw_title_in_portal'   => 'Custom Decimal',
        'visible_in_portal'     => true,
        'editable_in_portal'    => true,
        'required_in_portal'    => true,
        'tag'                   => nil,
        'created_at'            => '2015-12-15 12:08:26 UTC',
        'updated_at'            => '2015-12-15 12:22:30 UTC',
        'removable'             => true,
        'agent_description'     => nil
      }
    end

    context 'when field is a decimal' do
      let(:resource) do
        ZendeskAPI::TicketField.new(
          nil,
          base_resource.merge(
            {
              'title' => 'Custom Decimal',
              'type'  => 'decimal',
            }
          )
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['custom_decimal'])
      end
    end

    context 'when field is a checkbox' do
      let(:resource) do
        ZendeskAPI::TicketField.new(
          nil,
          base_resource.merge(
            {
              'title' => 'Custom Checkbox',
              'type'  => 'checkbox',
            }
          )
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['custom_checkbox'])
      end
    end

    context 'when field is a date' do
      let(:resource) do
        ZendeskAPI::TicketField.new(
          nil,
          base_resource.merge(
            {
              'title' => 'Custom Date',
              'type'  => 'date',
            }
          )
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['custom_date'])
      end
    end

    context 'when field is an integer' do
      let(:resource) do
        ZendeskAPI::TicketField.new(
          nil,
          base_resource.merge(
            {
              'title' => 'Custom Integer',
              'type'  => 'integer',
            }
          )
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['custom_integer'])
      end
    end

    context 'when field is a regex' do
      let(:resource) do
        ZendeskAPI::TicketField.new(
          nil,
          base_resource.merge(
            {
              'title' => 'Custom Regex',
              'type'  => 'regexp',
            }
          )
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['custom_regex'])
      end
    end

    context 'when field is a dropdown' do
      let(:resource) do
        ZendeskAPI::TicketField.new(
          nil,
          base_resource.merge(
            {
              'title'                => 'Custom Dropdown',
              'type'                 => 'dropdown',
              'custom_field_options' => [
                {
                  'id'       => 28_353_445,
                  'name'     => 'Another Value',
                  'raw_name' => 'Another Value',
                  'value'    => 'anotherkey',
                  'default'  => false
                },
                {
                  'id'       => 28_353_425,
                  'name'     => 'Value 1',
                  'raw_name' => 'Value 1',
                  'value'    => 'key1',
                  'default'  => false
                },
                {
                  'id'       => 28_353_435,
                  'name'     => 'Value 2',
                  'raw_name' => 'Value 2',
                  'value'    => 'key2',
                  'default'  => false
                }
              ]
            }
          )
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['custom_dropdown'])
      end
    end

    context 'when field is a multiselect' do
      let(:resource) do
        ZendeskAPI::TicketField.new(
          nil,
          base_resource.merge(
            {
              'title'                => 'Custom Multiselect',
              'type'                 => 'multiselect',
              'custom_field_options' => [
                {
                  'id'       => 28_353_445,
                  'name'     => 'Another Value',
                  'raw_name' => 'Another Value',
                  'value'    => 'anotherkey',
                  'default'  => false
                },
                {
                  'id'       => 28_353_425,
                  'name'     => 'Value 1',
                  'raw_name' => 'Value 1',
                  'value'    => 'key1',
                  'default'  => false
                },
                {
                  'id'       => 28_353_435,
                  'name'     => 'Value 2',
                  'raw_name' => 'Value 2',
                  'value'    => 'key2',
                  'default'  => false
                }
              ]
            }
          )
        )
      end

      it 'adds a custom field' do
        expect { process(process_payload) }.to change(Ticket, :column_names).by(['custom_multiselect'])
      end
    end

    context 'when field is the ticket type' do
      let(:resource) do
        ZendeskAPI::TicketField.new(
          nil,
          base_resource.merge(
            {
              'title'                => 'Type',
              'type'                 => 'tickettype',
              'system_field_options' => [
                {
                  'name'  => 'Question',
                  'value' => 'question'
                },
                {
                  'name'  => 'Incident',
                  'value' => 'incident'
                },
                {
                  'name'  => 'Problem',
                  'value' => 'problem'
                },
                {
                  'name'  => 'Task',
                  'value' => 'task'
                }
              ]
            }
          )
        )
      end

      it "activate the already existing ticket 'type' field" do
        expect { process(process_payload) }.to change { ObjectManager::Attribute.get(object: 'Ticket', name: 'type').active }.from(false).to(true)
      end

      it "import the fixed option list for the ticket 'type' field" do
        process(process_payload)
        expect(ObjectManager::Attribute.get(object: 'Ticket', name: 'type').data_option[:options]).to include(resource['system_field_options'].to_h { |choice| [choice['value'], choice['name']] })
      end
    end

    context 'when field is unknown' do
      let(:resource) do
        ZendeskAPI::TicketField.new(
          nil,
          base_resource.merge(
            {
              'title' => 'Custom Unknown',
              'type'  => 'unknown',
            }
          )
        )
      end

      it 'does not add a custom field' do
        expect { process(process_payload) }.not_to change(Ticket, :column_names)
      end
    end

  end
end
