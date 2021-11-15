# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MapTranslationTimeFields < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    connection.exec_update(<<-UPDATE_STATEMENT, 'SQL')
      UPDATE  translations
      SET     source='FORMAT_DATE'
      WHERE   source='date'
    UPDATE_STATEMENT

    connection.exec_update(<<-UPDATE_STATEMENT, 'SQL')
      UPDATE  translations
      SET     source='FORMAT_DATETIME'
      WHERE   source='timestamp'
    UPDATE_STATEMENT

  end

end
