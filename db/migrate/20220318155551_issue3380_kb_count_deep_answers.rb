# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Issue3380KbCountDeepAnswers < ActiveRecord::Migration[6.0]
  def up
    return if !Setting.exists?(name: 'system_init_done')

    add_column :knowledge_bases, :deep_answers_counter, :boolean, default: false
    KnowledgeBase.reset_column_information
  end
end
