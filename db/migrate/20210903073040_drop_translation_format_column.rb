# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class DropTranslationFormatColumn < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    remove_column :translations, :format, :string
    Translation.reset_column_information
  end
end
