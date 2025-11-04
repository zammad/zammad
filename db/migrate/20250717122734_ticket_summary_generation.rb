# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TicketSummaryGeneration < ActiveRecord::Migration[7.2]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    update_ticket_summary_config
    add_column :groups, :summary_generation, :string, null: false, default: 'global_default'
    Group.reset_column_information

    create_group_object_attribute

    init_core_workflow
  end

  def update_ticket_summary_config
    setting = Setting.get('ai_assistance_ticket_summary_config')

    setting['generate_on'] = 'on_ticket_detail_opening'

    Setting.set('ai_assistance_ticket_summary_config', setting)
  end

  def create_group_object_attribute
    ObjectManager::Attribute.add(
      force:         true,
      object:        'Group',
      name:          'summary_generation',
      display:       'Summary Generation',
      data_type:     'select',
      data_option:   {
        default:    'global_default',
        options:    [
          {
            name:  'Use global default',
            value: 'global_default'
          },
          {
            name:  'On ticket detail opening',
            value: 'on_ticket_detail_opening'
          },
          {
            name:  'On ticket summary sidebar activation',
            value: 'on_ticket_summary_sidebar_activation'
          }
        ],
        nulloption: false,
        multiple:   false,
        null:       false,
        translate:  true,
      },
      editable:      true,
      active:        true,
      screens:       {
        create: {
          '-all-' => {
            null: false,
          },
        },
        edit:   {
          '-all-' => {
            null: false,
          },
        },
      },
      to_create:     false,
      to_migrate:    false,
      to_delete:     false,
      position:      1450,
      created_by_id: 1,
      updated_by_id: 1,
    )
  end

  def init_core_workflow
    CoreWorkflow.create_if_not_exists(
      name:            'base - show summary generation',
      object:          'Group',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::AdminGroupSummaryGeneration',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::AdminGroupSummaryGeneration']
        },
      },
      changeable:      false,
      created_by_id:   1,
      updated_by_id:   1,
    )
  end
end
