# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class VectorDBKnowledgeBaseSettings < ActiveRecord::Migration[8.0]
  def change
    # return if it's a new setup
    return if !Setting.exists?(name: 'system_init_done')

    Setting.create_if_not_exists(
      title:       'Vector DB knowledge base categories',
      name:        'vectordb_knowledge_base_category_ids',
      area:        'VectorDB::KnowledgeBase',
      description: 'Defines which knowledge base categories are included in the vector database. Leave empty to include answers from all categories.',
      state:       [],
      frontend:    false,
    )

    Setting.create_if_not_exists(
      title:       'Vector DB knowledge base chunking strategy',
      name:        'vectordb_knowledge_base_chunking_strategy',
      area:        'VectorDB::KnowledgeBase',
      description: 'Defines the chunking strategy for the knowledge base vector database.',
      options:     {
        form: [
          {
            display: '',
            null:    true,
            name:    'vectordb_knowledge_base_chunking_strategy',
            tag:     'select',
            options: {
              'recursive' => 'Recursive hierarchical chunking',
              'sentence'  => 'Sentence-based chunking',
            },
          },
        ],
      },
      state:       'sentence',
      frontend:    false,
    )
  end
end
