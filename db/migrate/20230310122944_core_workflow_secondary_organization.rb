# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflowSecondaryOrganization < ActiveRecord::Migration[6.1]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    CoreWorkflow.create_if_not_exists(
      name:            'base - show secondary organization based on user',
      object:          'Ticket',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::SecondaryOrganization',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::SecondaryOrganization']
        },
      },
      changeable:      false,
      created_by_id:   1,
      updated_by_id:   1,
    )
  end
end
