# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UpdateSessionTimeoutDropdown < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    change_column :settings, :options, :text, null: true
    Setting.reset_column_information

    update_setting
  end

  def options
    [ { value: '0', name: 'disabled' }, { value: 1.hour.seconds, name: '1 hour' }, { value: 2.hours.seconds, name: '2 hours' }, { value: 1.day.seconds, name: '1 day' }, { value: 7.days.seconds, name: '1 week' }, { value: 14.days.seconds, name: '2 weeks' }, { value: 21.days.seconds, name: '3 weeks' }, { value: 28.days.seconds, name: '4 weeks' } ]
  end

  def update_setting
    setting = Setting.find_by(name: 'session_timeout')
    setting.options = {
      form: [
        {
          display:   'Default',
          null:      false,
          name:      'default',
          tag:       'select',
          options:   options,
          translate: true,
        },
        {
          display:   'admin',
          null:      false,
          name:      'admin',
          tag:       'select',
          options:   options,
          translate: true,
        },
        {
          display:   'ticket.agent',
          null:      false,
          name:      'ticket.agent',
          tag:       'select',
          options:   options,
          translate: true,
        },
        {
          display:   'ticket.customer',
          null:      false,
          name:      'ticket.customer',
          tag:       'select',
          options:   options,
          translate: true,
        },
      ]
    }
    setting.save!
  end
end
