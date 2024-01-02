# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TicketTimeAccountingCheck < ActiveRecord::Migration[6.1]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_workflow
    update_time_accounting_selector
  end

  def add_workflow
    CoreWorkflow.create_if_not_exists(
      name:            'base - ticket time accouting check',
      object:          'Ticket',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::TicketTimeAccountingCheck',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::TicketTimeAccountingCheck']
        },
      },
      changeable:      false,
      priority:        99_999,
      created_by_id:   1,
      updated_by_id:   1,
    )
  end

  def update_time_accounting_selector
    selector = Setting.get('time_accounting_selector')
    return if selector.blank?
    return if selector[:condition].blank?

    selector[:condition].each_value do |value|
      if value[:pre_condition] == 'not_set'
        value[:operator] = 'not set'
        value.delete(:pre_condition)
        value.delete(:value)
        value.delete(:value_completion)
      end
      if value[:operator] == 'contains'
        value[:operator] = 'regex match'
      end
      if value[:operator] == 'contains not'
        value[:operator] = 'regex mismatch'
      end
    end

    Setting.set('time_accounting_selector', selector)
  end
end
