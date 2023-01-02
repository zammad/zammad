# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Import::Freshdesk::Tickets, db_strategy: 'reset', sequencer: :unit do
  context 'when importing ticket list from freshdesk' do
    let(:group) { create(:group) }
    let(:owner) { create(:agent, group_ids: [group.id]) }

    let(:id_map) do
      {
        'User'  => {
          80_014_400_475 => owner.id,
        },
        'Group' => {
          80_000_374_718 => group.id,
        },
      }
    end

    let(:ticket_data) do
      {
        'cc_emails'                => [],
        'fwd_emails'               => [],
        'reply_cc_emails'          => [],
        'ticket_cc_emails'         => [],
        'fr_escalated'             => false,
        'spam'                     => false,
        'email_config_id'          => nil,
        'group_id'                 => 80_000_374_718,
        'priority'                 => 1,
        'requester_id'             => 80_014_400_475,
        'responder_id'             => 80_014_400_475,
        'source'                   => 3,
        'company_id'               => nil,
        'status'                   => 2,
        'subject'                  => 'Inline Images Failing?',
        'association_type'         => nil,
        'support_email'            => nil,
        'to_emails'                => ['info@zammad.org'],
        'product_id'               => nil,
        'type'                     => nil,
        'due_by'                   => '2021-05-17T12:29:27Z',
        'fr_due_by'                => '2021-05-15T12:29:27Z',
        'is_escalated'             => false,
        'custom_fields'            => {},
        'created_at'               => '2021-05-14T12:29:27Z',
        'updated_at'               => '2021-05-14T12:30:19Z',
        'associated_tickets_count' => nil,
        'tags'                     => [],
      }
    end

    let(:resources_payloud) do
      [
        ticket_data.merge(
          id: 10
        ),
        ticket_data.merge(
          id: 11
        ),
      ]
    end

    let(:process_payload) do
      {
        import_job:           build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:              false,
        request_params:       {},
        field_map:            {},
        id_map:               id_map,
        time_entry_available: true,
      }
    end

    before do
      # We only want to test here the Ticket API, so disable other modules in the sequence
      #   that make their own HTTP requests.
      custom_sequence = Sequencer::Sequence::Import::Freshdesk::Ticket.sequence.dup
      custom_sequence.delete('Import::Freshdesk::Ticket::Fetch')
      custom_sequence.delete('Import::Freshdesk::Ticket::TimeEntries')
      custom_sequence.delete('Import::Freshdesk::Ticket::Conversations')
      allow(Sequencer::Sequence::Import::Freshdesk::Ticket).to receive(:sequence) { custom_sequence }

      # Mock the groups get request
      stub_request(:get, 'https://yours.freshdesk.com/api/v2/tickets?order_by=updated_at&order_type=asc&page=1&per_page=100&updated_since=1970-01-01').to_return(status: 200, body: JSON.generate(resources_payloud), headers: {})
    end

    context 'when page limit is not reached' do
      it 'check ticket count' do
        expect { process(process_payload) }.to change(Ticket, :count).by(2)
      end
    end

    context 'when page limit is reached' do
      let(:resources_payloud_second_cycle) do
        [
          ticket_data.merge(
            id: 11
          ),
          ticket_data.merge(
            id: 12
          ),

          # Subject was changed during the import.
          ticket_data.merge(
            id:      10,
            subject: 'Different subject'
          ),
        ]
      end

      before do
        stub_request(:get, 'https://yours.freshdesk.com/api/v2/tickets?order_by=updated_at&order_type=asc&page=1&per_page=100&updated_since=1970-01-01').to_return(status: 200, body: JSON.generate(resources_payloud), headers: { link: 'second-page' })
        stub_request(:get, 'https://yours.freshdesk.com/api/v2/tickets?order_by=updated_at&order_type=asc&page=1&per_page=100&&updated_since=2021-05-14T12:30:19Z').to_return(status: 200, body: JSON.generate(resources_payloud_second_cycle), headers: {})
      end

      it 'check ticket count' do
        expect do
          process(process_payload) do |instance|
            # Set the `page_cycle` to zero, so that we trigger a new cycle (normally if more then 30.000 tickets exists)
            allow(instance).to receive(:page_cycle).and_return(0)
          end
        end.to change(Ticket, :count).by(3)
      end

      it 'check that ticket title was changed during import' do
        process(process_payload) do |instance|
          # Set the `page_cycle` to zero, so that we trigger a new cycle (normally if more then 30.000 tickets exists)
          allow(instance).to receive(:page_cycle).and_return(0)
        end

        expect(Ticket.find_by(number: 10).title).to eq('Different subject')
      end
    end
  end
end
