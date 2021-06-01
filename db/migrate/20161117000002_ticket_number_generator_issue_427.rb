# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketNumberGeneratorIssue427 < ActiveRecord::Migration[4.2]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting = Setting.find_by(name: 'ticket_number')
    setting.preferences = {
      settings_included: %w[ticket_number_increment ticket_number_date],
      controller:        'SettingsAreaTicketNumber',
      permission:        ['admin.ticket'],
    }
    setting.save!
    setting = Setting.find_by(name: 'ticket_number_increment')
    setting.preferences = {
      permission: ['admin.ticket'],
      hidden:     true,
    }
    setting.save!
    setting = Setting.find_by(name: 'ticket_number_date')
    setting.preferences = {
      permission: ['admin.ticket'],
      hidden:     true,
    }

    # just to make sure that value is saved correctly - https://github.com/zammad/zammad/issues/413
    if setting.state_current['value'] == true || setting.state_current['value'] == false
      setting.state_current['value'] = { 'checksum' => setting.state_current['value'] }
    end
    setting.save!

    setting = Setting.find_by(name: 'ticket_hook_position')
    setting.preferences = {
      controller: 'SettingsAreaTicketHookPosition',
      permission: ['admin.ticket'],
    }
    setting.options = {
      form: [
        {
          display:   '',
          null:      true,
          name:      'ticket_hook_position',
          tag:       'select',
          translate: true,
          options:   {
            'left'  => 'left',
            'right' => 'right',
            'none'  => 'none',
          },
        },
      ],
    }
    setting.save!

  end
end
