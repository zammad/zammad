# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AddTranslationFilesChecksumToLocales < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :locales, :translation_files_checksum, :string, limit: 64, null: true

    Locale.reset_column_information
  end
end
