# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AndOrConditionsSettingDefault, type: :db_migration do
  before do
    Setting.find_by(name: 'ticket_allow_expert_conditions').destroy!
    Setting.create(
      title:       'Ticket Conditions Expert Mode',
      name:        'ticket_allow_expert_conditions',
      area:        'Ticket::Base',
      description: 'Defines if the ticket conditions editor supports complex logical expressions.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'ticket_allow_expert_conditions',
            tag:     'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:       4000,
        permission: ['admin.ticket'],
      },
      frontend:    true
    )

    migrate
  end

  it 'does migrate ticket_allow_expert_conditions setting' do
    expect(Setting.find_by(name: 'ticket_allow_expert_conditions')).to have_attributes(
      area:          'Ticket::Core',
      state_current: {
        value: true,
      },
      state_initial: {
        value: true,
      },
      preferences:   {
        online_service_disable: true,
        permission:             ['admin.ticket'],
      }
    )
  end
end
