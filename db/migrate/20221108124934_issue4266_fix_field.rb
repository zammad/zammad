# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue4266FixField < ActiveRecord::Migration[6.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    setting                           = Setting.find_by(name: 'customer_ticket_create_group_ids')
    setting.description               = 'Defines groups for which a customer can create tickets via web interface. No selection means all groups are available.'
    setting.options['form'][0]['tag'] = 'multiselect'
    setting.options['form'][0].delete('nulloption')
    setting.save!

    value = Setting.get('customer_ticket_create_group_ids')
    if ['', ['']].include?(value)
      value = nil
    end
    Setting.set('customer_ticket_create_group_ids', value)
  end
end
