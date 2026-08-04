# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Issue6248VectorDBKbExcludedCategories < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    # The opt-in allowlist is replaced by an opt-out denylist: all categories are indexed by default,
    # so there is nothing to carry over from the old setting (an allowlist of a few categories would
    # translate into "exclude everything else", which is the opposite of the new default).
    Setting.find_by(name: 'vectordb_knowledge_base_category_ids')&.destroy

    Setting.create_if_not_exists(
      title:       'Vector DB knowledge base excluded categories',
      name:        'vectordb_knowledge_base_excluded_category_ids',
      area:        'VectorDB::KnowledgeBase',
      description: 'Defines which knowledge base categories are excluded from the vector database. Sub-categories of an excluded category are excluded as well. Note that the vector database has to be rebuilt after removing a category from this list, so that its answers get indexed.',
      state:       [],
      frontend:    false,
    )
  end
end
