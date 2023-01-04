# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Freshdesk::TimeEntry, sequencer: :sequence do

  context 'when importing time_entry from Freshdesk' do

    let(:resource) do
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
      }
    end

    let(:ticket) { create(:ticket) }
    let(:id_map) do
      {
        'Ticket' => {
          1001 => ticket.id,
        },
        'User'   => {
          80_014_400_475 => 1,
        }
      }
    end
    let(:process_payload) do
      {
        import_job: build_stubbed(:import_job, name: 'Import::Freshdesk', payload: {}),
        dry_run:    false,
        resource:   resource,
        field_map:  {},
        id_map:     id_map,
      }
    end

    let(:imported_time_entry) do
      {
        ticket_id:     ticket.id,
        created_by_id: 1,
        time_unit:     80,
      }
    end

    it 'adds time entry' do
      expect { process(process_payload) }.to change(Ticket::TimeAccounting, :count).by(1)
    end

    it 'correct attributes for added time entry' do
      process(process_payload)
      Rails.logger.debug Ticket::TimeAccounting.last
      expect(Ticket::TimeAccounting.last).to have_attributes(imported_time_entry)
    end

    it 'updates already existing article' do
      expect do
        process(process_payload)
        process(process_payload)
      end.to change(Ticket::TimeAccounting, :count).by(1)
    end
  end
end
