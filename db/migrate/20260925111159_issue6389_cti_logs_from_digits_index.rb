# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6389CtiLogsFromDigitsIndex < ActiveRecord::Migration[8.1]
  def up
    # return if it's a new setup (fresh installs get the index from CreateBase)
    return if !Setting.exists?(name: 'system_init_done')

    add_index :cti_logs, "regexp_replace(\"from\", '\\D', '', 'g')", name: 'index_cti_logs_on_from_digits', if_not_exists: true

    # The exact lookup on the raw number was its only reader.
    remove_index :cti_logs, name: 'index_cti_logs_on_from', if_exists: true
  end

  def down
    # Guarded like up, so a rollback on a fresh install keeps the index from CreateBase.
    return if !Setting.exists?(name: 'system_init_done')

    add_index :cti_logs, [:from], if_not_exists: true
    remove_index :cti_logs, name: 'index_cti_logs_on_from_digits', if_exists: true
  end
end
