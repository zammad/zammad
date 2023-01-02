# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Issue3671HttpLogsUnlimitRequestResponse < ActiveRecord::Migration[6.1]
  def up

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :http_logs do |t|
      t.change :url, :text
      t.change :request, :text
      t.change :response, :text
    end

    HttpLog.reset_column_information
  end
end
