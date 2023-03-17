# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Freshdesk::TimeEntries, db_strategy: 'reset', sequencer: :sequence do
  let(:time_entry_available) { true }
  let(:ticket)               { create(:ticket) }

  let(:process_payload) do
    {
      import_job:           build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
      dry_run:              false,
      object:               'TimeEntry',
      request_params:       {
        ticket: {
          'id' => 1001,
        },
      },
      field_map:            {},
      id_map:               {
        'Ticket' => {
          1001 => ticket.id,
        },
        'User'   => {
          80_014_400_475 => 1,
        }
      },
      skipped_resource_id:  nil,
      time_entry_available: time_entry_available,
    }
  end

  context 'when time entry feature is available' do
    let(:resources_payloud) do
      [
        {
          'id'            => 80_027_218_656,
          'billable'      => true,
          'note'          => 'Example Preparation',
          'timer_running' => false,
          'agent_id'      => 80_014_400_475,
          'ticket_id'     => 1001,
          'time_spent'    => '01:20',
          'created_at'    => '2021-05-14T12:29:27Z',
          'updated_at'    => '2021-05-14T12:29:27Z',
          'start_time'    => '2021-05-14T12:29:27Z',
          'executed_at'   => '2021-05-14T12:29:27Z'
        },
        {
          'id'            => 80_027_218_657,
          'billable'      => true,
          'note'          => 'Example Preparation 2',
          'timer_running' => false,
          'agent_id'      => 80_014_400_475,
          'ticket_id'     => 1001,
          'time_spent'    => '02:20',
          'created_at'    => '2021-05-15T12:29:27Z',
          'updated_at'    => '2021-05-15T12:29:27Z',
          'start_time'    => '2021-05-15T12:29:27Z',
          'executed_at'   => '2021-05-15T12:29:27Z'
        }
      ]
    end

    let(:imported_time_entry) do
      {
        ticket_id:     ticket.id,
        created_by_id: 1,
        time_unit:     140,
      }
    end

    before do
      # Mock the groups get request
      stub_request(:get, 'https://yours.freshdesk.com/api/v2/tickets/1001/time_entries?per_page=100').to_return(status: 200, body: JSON.generate(resources_payloud), headers: {})
    end

    it 'add time entry for ticket' do
      expect { process(process_payload) }.to change(Ticket::TimeAccounting, :count).by(2)
    end

    it 'check last time unit for ticket' do
      process(process_payload)
      expect(Ticket::TimeAccounting.last).to have_attributes(imported_time_entry)
    end

    context 'with empty time entries' do
      let(:resources_payloud) { [] }

      it 'do not change time entry for ticket' do
        expect { process(process_payload) }.not_to change(Ticket::TimeAccounting, :count)
      end
    end
  end

  context 'when time entry feature is not available' do
    let(:time_entry_available) { false }

    it 'add time entry for ticket' do
      expect { process(process_payload) }.not_to change(Ticket::TimeAccounting, :count)
    end
  end
end
