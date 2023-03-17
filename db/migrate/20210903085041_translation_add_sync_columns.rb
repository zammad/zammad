# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TranslationAddSyncColumns < ActiveRecord::Migration[6.0]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_column :translations, :is_synchronized_from_codebase, :boolean, null: false, default: false
    add_column :translations, :synchronized_from_translation_file, :string, limit: 255

    Translation.reset_column_information

  end
end
