# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Issue4838DataRetention < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :jobs, :object, :string, limit: 100, null: true # optional for now

    Job.reset_column_information

    Job.update_all(object: 'Ticket') # rubocop:disable Rails/SkipsModelValidations

    change_column :jobs, :object, :string, limit: 100, null: false

    Job.reset_column_information
  end
end
