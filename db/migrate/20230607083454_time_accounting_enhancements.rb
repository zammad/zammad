# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TimeAccountingEnhancements < ActiveRecord::Migration[5.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    create_ticket_time_accounting_types_table
    create_ticket_time_accounting_unit_settings
    create_ticket_time_accounting_type_settings
  end

  private

  def create_ticket_time_accounting_types_table
    create_table :ticket_time_accounting_types do |t|
      t.column :name,                 :string, limit: 250, null: false
      t.column :note,                 :string, limit: 250, null: true
      t.column :active,               :boolean,            null: false, default: true
      t.column :updated_by_id,        :integer,            null: false
      t.column :created_by_id,        :integer,            null: false
      t.timestamps limit: 3, null: false
    end

    add_index :ticket_time_accounting_types, [:name], unique: true

    add_foreign_key :ticket_time_accounting_types, :users, column: :created_by_id
    add_foreign_key :ticket_time_accounting_types, :users, column: :updated_by_id

    change_table :ticket_time_accountings do |t|
      t.column :type_id, :integer, null: true
    end

    add_foreign_key :ticket_time_accountings, :ticket_time_accounting_types, column: :type_id

    Ticket::TimeAccounting.reset_column_information
  end

  def create_ticket_time_accounting_unit_settings
    Setting.create_if_not_exists(
      title:       'Time Accounting Unit',
      name:        'time_accounting_unit',
      area:        'Web::Base',
      description: 'Defines the unit to be shown next to the time accounting input field.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.time_accounting'],
      },
      state:       '',
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Time Accounting Custom Unit',
      name:        'time_accounting_unit_custom',
      area:        'Web::Base',
      description: 'Defines the custom unit to be shown next to the time accounting input field.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.time_accounting'],
      },
      state:       '',
      frontend:    true
    )
  end

  def create_ticket_time_accounting_type_settings
    Setting.create_if_not_exists(
      title:       'Time Accounting Types',
      name:        'time_accounting_types',
      area:        'Web::Base',
      description: 'Defines if the time accounting types are enabled.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.time_accounting'],
      },
      state:       false,
      frontend:    true
    )

    Setting.create_if_not_exists(
      title:       'Time Accounting Default Type',
      name:        'time_accounting_type_default',
      area:        'Web::Base',
      description: 'Defines the default time accounting type.',
      options:     {
        form: [
          {},
        ],
      },
      preferences: {
        authentication: true,
        permission:     ['admin.time_accounting'],
      },
      state:       '',
      frontend:    true
    )
  end
end
