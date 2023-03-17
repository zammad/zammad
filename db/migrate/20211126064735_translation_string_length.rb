# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TranslationStringLength < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # Increase translation string length from 500 to 3000.
    change_column(:translations, :source, :string, limit: 3000)
    change_column(:translations, :target, :string, limit: 3000)
    change_column(:translations, :target_initial, :string, limit: 3000)
    Translation.reset_column_information
  end
end
