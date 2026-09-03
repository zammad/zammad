# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBaseSortingMode, current_user_id: 1, db_strategy: :reset, type: :db_migration do
  # The content an upgrading installation already has, created while the columns are still in place
  #   — what it was sorting by then is beside the point, since `add_column` stamps its own value
  #   onto every row.
  let(:knowledge_base) { create(:knowledge_base) }
  let(:category)       { create(:knowledge_base_category, knowledge_base:) }

  before do
    category

    without_column :knowledge_bases,           column: :category_sorting_mode
    without_column :knowledge_base_categories, column: %i[category_sorting_mode answer_sorting_mode]

    KnowledgeBase.reset_column_information
    KnowledgeBase::Category.reset_column_information
  end

  # The whole point of backfilling `manual`: an editor who arranged their content by hand finds it
  #   in that order after the upgrade, rather than suddenly re-sorted by title.
  it 'carries content that predates the columns over on hand-made order', :aggregate_failures do
    migrate

    expect(knowledge_base.reload.category_sorting_mode).to eq('manual')
    expect(category.reload).to have_attributes(category_sorting_mode: 'manual', answer_sorting_mode: 'manual')
  end

  # And the default then moves on, so the upgraded installation agrees with a fresh one
  #   (InitializeKnowledgeBase) about what new content starts with.
  it 'starts content created after the upgrade on the default mode', :aggregate_failures do
    migrate

    expect(KnowledgeBase.new.category_sorting_mode).to eq(KnowledgeBase::DEFAULT_SORTING_MODE)
    expect(KnowledgeBase::Category.new).to have_attributes(
      category_sorting_mode: KnowledgeBase::DEFAULT_SORTING_MODE,
      answer_sorting_mode:   KnowledgeBase::DEFAULT_SORTING_MODE
    )
  end
end
