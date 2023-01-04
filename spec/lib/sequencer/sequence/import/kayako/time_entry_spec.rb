# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Sequence::Import::Kayako::TimeEntry, sequencer: :sequence do

  context 'when importing time_entry from Kayako' do

    let(:resource) do
      {
        'id'                   => 51,
        'time_tracking_log_id' => 51,
        'case'                 => {
          'id'            => 1001,
          'resource_type' => 'case'
        },
        'agent'                => {
          'id'            => 80_014_400_475,
          'resource_type' => 'user'
        },
        'log_type'             => 'WORKED',
        'time_spent'           => 3600,
        'creator'              => {
          'id'            => 80_014_400_475,
          'resource_type' => 'user'
        },
        'created_at'           => '2021-08-27T20:38:30+00:00',
        'updated_at'           => '2021-08-27T20:38:30+00:00',
        'resource_type'        => 'timetracking_log',
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
        import_job:       build_stubbed(:import_job, name: 'Import::Kayako', payload: {}),
        dry_run:          false,
        resource:         resource,
        field_map:        {},
        id_map:           id_map,
        default_language: 'en-us'
      }
    end

    let(:imported_time_entry) do
      {
        ticket_id:     ticket.id,
        created_by_id: 1,
        time_unit:     60,
      }
    end

    it 'adds time entry' do
      expect { process(process_payload) }.to change(Ticket::TimeAccounting, :count).by(1)
    end

    it 'correct attributes for added time entry' do
      process(process_payload)
      expect(Ticket::TimeAccounting.last).to have_attributes(imported_time_entry)
    end

    context 'when time entry should be skipped' do
      let(:resource) do
        super().merge(
          'log_type' => 'VIEWED'
        )
      end

      it 'skip time entry' do
        expect { process(process_payload) }.not_to change(Ticket::TimeAccounting, :count)
      end
    end
  end
end
