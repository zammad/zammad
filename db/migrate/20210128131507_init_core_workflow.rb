# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class InitCoreWorkflow < ActiveRecord::Migration[5.2]
  def change
    return if !Setting.exists?(name: 'system_init_done')

    add_table
    add_setting_ajax
    fix_invalid_screens
    fix_pending_time
    fix_organization_screens
    fix_user_screens
    add_workflows
  end

  def add_table # rubocop:disable Metrics/AbcSize
    create_table :core_workflows do |t|
      t.string :name,                     limit: 100, null: false
      t.string :object,                   limit: 100, null: true
      t.text   :preferences,              limit: 500.kilobytes + 1, null: true
      t.text   :condition_saved,          limit: 500.kilobytes + 1, null: true
      t.text   :condition_selected,       limit: 500.kilobytes + 1, null: true
      t.text   :perform,                  limit: 500.kilobytes + 1, null: true
      t.boolean :active,                  null: false, default: true
      t.boolean :stop_after_match,        null: false, default: false
      t.boolean :changeable,              null: false, default: true
      t.integer :priority,                null: false, default: 0
      t.integer :updated_by_id,           null: false
      t.integer :created_by_id,           null: false
      t.timestamps limit: 3, null: false
    end
    add_index :core_workflows, [:name], unique: true
    add_foreign_key :core_workflows, :users, column: :created_by_id
    add_foreign_key :core_workflows, :users, column: :updated_by_id
  end

  def add_setting_ajax
    Setting.create_if_not_exists(
      title:       'Core Workflow Ajax Mode',
      name:        'core_workflow_ajax_mode',
      area:        'System::UI',
      description: 'Defines if the core workflow communication should run over AJAX instead of websockets.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'core_workflow_ajax_mode',
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
        prio:       3,
        permission: ['admin.system'],
      },
      frontend:    true
    )
  end

  def fix_invalid_screens
    ObjectManager::Attribute.where(object_lookup_id: [ ObjectLookup.by_name('User'), ObjectLookup.by_name('Organization') ], editable: false).each do |attribute|
      next if attribute.screens[:edit].blank?
      next if attribute.screens[:create].present?

      attribute.screens[:create] = attribute.screens[:edit]
      attribute.save
    end
  end

  def fix_pending_time
    pending_time = ObjectManager::Attribute.find_by(name: 'pending_time', object_lookup: ObjectLookup.find_by(name: 'Ticket'))
    return if pending_time.blank?

    pending_time.data_option.delete('required_if')
    pending_time.data_option.delete('shown_if')
    pending_time.save
  end

  def fix_organization_screens
    %w[domain note].each do |name|
      field = ObjectManager::Attribute.find_by(name: name, object_lookup: ObjectLookup.find_by(name: 'Organization'))
      next if field.blank?

      field.screens['create'] ||= {}
      field.screens['create']['-all-'] ||= {}
      field.screens['create']['-all-']['null'] = true
      field.save
    end
  end

  def fix_user_screens
    %w[email web phone mobile organization_id fax department street zip city country address password vip note role_ids].each do |name|
      field = ObjectManager::Attribute.find_by(name: name, object_lookup: ObjectLookup.find_by(name: 'User'))
      next if field.blank?

      field.screens['create'] ||= {}
      field.screens['create']['-all-'] ||= {}
      field.screens['create']['-all-']['null'] = true
      field.save
    end
  end

  def add_workflows
    CoreWorkflow.create_if_not_exists(
      name:            'base - hide pending time on non pending states',
      object:          'Ticket',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::PendingTime',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::PendingTime']
        },
      },
      changeable:      false,
      created_by_id:   1,
      updated_by_id:   1,
    )
    CoreWorkflow.create_if_not_exists(
      name:            'base - admin sla options',
      object:          'Sla',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::AdminSla',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::AdminSla']
        },
      },
      changeable:      false,
      created_by_id:   1,
      updated_by_id:   1,
    )
    CoreWorkflow.create_if_not_exists(
      name:            'base - core workflow',
      object:          'CoreWorkflow',
      condition_saved: {
        'custom.module': {
          operator: 'match all modules',
          value:    [
            'CoreWorkflow::Custom::AdminCoreWorkflow',
          ],
        },
      },
      perform:         {
        'custom.module': {
          execute: ['CoreWorkflow::Custom::AdminCoreWorkflow']
        },
      },
      changeable:      false,
      created_by_id:   1,
      updated_by_id:   1,
    )
  end
end
