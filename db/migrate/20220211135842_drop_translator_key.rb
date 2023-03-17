# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class DropTranslatorKey < ActiveRecord::Migration[6.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.find_by(name: 'translator_key')&.destroy
  end
end
