# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class AddTicketTimeAccounting373 < ActiveRecord::Migration[4.2]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    drop_table :ticket_time_accounting
    create_table :ticket_time_accountings do |t|
      t.references :ticket,                                       null: false
      t.references :ticket_article,                               null: true
      t.column :time_unit,      :decimal, precision: 6, scale: 2, null: false
      t.column :created_by_id,  :integer,                         null: false
      t.timestamps limit: 3, null: false
    end
    add_index :ticket_time_accountings, [:ticket_id]
    add_index :ticket_time_accountings, [:ticket_article_id]
    add_index :ticket_time_accountings, [:created_by_id]
    add_index :ticket_time_accountings, [:time_unit]

    add_column :tickets, :time_unit, :decimal, precision: 6, scale: 2, null: true
    add_index :tickets, [:time_unit]

    Cache.clear
  end
end
