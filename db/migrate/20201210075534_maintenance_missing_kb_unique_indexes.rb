# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MaintenanceMissingKbUniqueIndexes < ActiveRecord::Migration[5.2]
  def change

    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    add_index :knowledge_base_locales, %i[system_locale_id knowledge_base_id], name: 'index_kb_locale_on_kb_system_locale_kb', unique: true
    add_index :knowledge_base_translations, %i[kb_locale_id knowledge_base_id], name: 'index_kb_t_on_kb_locale_kb', unique: true
    add_index :knowledge_base_category_translations, %i[kb_locale_id category_id], name: 'index_kb_c_t_on_kb_locale_category', unique: true
    add_index :knowledge_base_answer_translations, %i[kb_locale_id answer_id], name: 'index_kb_a_t_on_kb_locale_answer', unique: true
  end
end
