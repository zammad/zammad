# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBaseSortingMode < ActiveRecord::Migration[8.0]
  def up
    # return if it's a new setup (fresh installs get the columns from InitializeKnowledgeBase)
    return if !Setting.exists?(name: 'system_init_done')

    # A mode per list, not per node: a category orders its subcategories and its answers
    #   independently, so it carries one column for each. The knowledge base root lists categories
    #   only and therefore has just the category one — under the same name, so both stacks read the
    #   same attribute for the same thing.
    #
    # `manual` here is the backfill value rather than the going-forward default: `add_column`
    #   stamps it onto every row that already exists, which is what keeps content an editor
    #   arranged by hand in the order they left it.
    add_column :knowledge_bases,           :category_sorting_mode, :string, limit: 30, null: false, default: 'manual', if_not_exists: true
    add_column :knowledge_base_categories, :category_sorting_mode, :string, limit: 30, null: false, default: 'manual', if_not_exists: true
    add_column :knowledge_base_categories, :answer_sorting_mode,   :string, limit: 30, null: false, default: 'manual', if_not_exists: true

    # With the existing rows carried over, the default moves on: content created from here starts
    #   alphabetically (KnowledgeBase::DEFAULT_SORTING_MODE), the same as on a fresh install
    #   (InitializeKnowledgeBase). Only rows inserted after this point are affected — the backfill
    #   above already wrote a value into every earlier one.
    change_column_default :knowledge_bases,           :category_sorting_mode, from: 'manual', to: 'alphabetical'
    change_column_default :knowledge_base_categories, :category_sorting_mode, from: 'manual', to: 'alphabetical'
    change_column_default :knowledge_base_categories, :answer_sorting_mode,   from: 'manual', to: 'alphabetical'

    KnowledgeBase.reset_column_information
    KnowledgeBase::Category.reset_column_information
  end
end
