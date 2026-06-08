# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KbAddDatesIndex < ActiveRecord::Migration[7.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    change_table :knowledge_base_answers do |t|
      # Covers published (published+internal) and internal (published+internal+archived) scopes
      t.index %i[published_at archived_at internal_at], name: 'index_kb_answers_publishing_dates'
      # Covers archived scope
      t.index [:archived_at]
    end

    KnowledgeBase::Answer.reset_column_information
  end
end
