# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe RenameTicketOverviewPriorityIconSetting, type: :db_migration do
  let(:setting) { restore_previous_setting }

  before do
    setting
  end

  it 'renames the existing setting' do
    expect { migrate }
      .to change  { setting.reload.title }.to('Ticket Priority Icons')
      .and change { setting.reload.name }.to('ui_ticket_priority_icons')
      .and change { setting.reload.area }.to('UI::Ticket::Priority')
      .and change { setting.reload.description }.to('Enables display of ticket priority icons in UI.')
      .and change { setting.reload.options[:form][0][:name] }.to('ui_ticket_priority_icons')
  end

  context 'when setting has a modified state' do
    before do
      setting.update!(state: true)
    end

    it 'preseves the existing value' do
      expect { migrate }
        .not_to change { setting.reload.state }
    end
  end

  def restore_previous_setting
    Setting
      .find_by(name: 'ui_ticket_priority_icons')
      .destroy!

    Setting.create!(
      title:       'Priority Icons in Overviews',
      name:        'ui_ticket_overview_priority_icon',
      area:        'UI::TicketOverview::PriorityIcons',
      description: 'Enables priority icons in ticket overviews.',
      options:     {
        form: [
          {
            display:   '',
            null:      true,
            name:      'ui_ticket_overview_priority_icon',
            tag:       'boolean',
            translate: true,
            options:   {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state:       false,
      preferences: {
        prio:       500,
        permission: ['admin.ui'],
      },
      frontend:    true
    )
  end
end
