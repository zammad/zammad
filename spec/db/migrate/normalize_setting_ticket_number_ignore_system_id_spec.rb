# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe NormalizeSettingTicketNumberIgnoreSystemId, type: :db_migration do
  before do
    Setting.find_by(name: 'ticket_number_ignore_system_id')&.destroy

    Setting.create(
      title:       'Ticket Number ignore system_id',
      name:        'ticket_number_ignore_system_id',
      area:        'Ticket::Core',
      description: '-',
      options:     {
        form: [
          {
            display: 'Ignore system_id',
            null:    true,
            name:    'ticket_number_ignore_system_id',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       {
        ticket_number_ignore_system_id: false
      },
      preferences: {
        permission: ['admin.ticket'],
        hidden:     true,
      },
      frontend:    false
    )
  end

  context 'when previous migration incorrectly sets "ticket_number_ignore_system_id" to hash' do
    it 'sets it to false' do
      expect { migrate }
        .to change { Setting.get('ticket_number_ignore_system_id') }
        .to(false)
    end

    it 'sets #state_initial to { value: false }' do
      expect { migrate }
        .to change { Setting.find_by(name: 'ticket_number_ignore_system_id').state_initial }
        .to({ 'value' => false })
    end
  end

  context 'when "ticket_number_ignore_system_id" Setting is a boolean' do
    before { Setting.set('ticket_number_ignore_system_id', true) }

    it 'makes no change' do
      expect { migrate }
        .not_to change { Setting.get('ticket_number_ignore_system_id') }
    end

    it 'sets #state_initial to { value: false }' do
      expect { migrate }
        .to change { Setting.find_by(name: 'ticket_number_ignore_system_id').state_initial }
        .to({ 'value' => false })
    end
  end

  context 'when no "ticket_number_ignore_system_id" Setting exists (edge case)' do
    before { Setting.find_by(name: 'ticket_number_ignore_system_id').destroy }

    it 'completes without error' do
      expect { migrate }.not_to raise_error
    end
  end
end
