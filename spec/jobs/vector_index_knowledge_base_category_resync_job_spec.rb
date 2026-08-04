# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe VectorIndexKnowledgeBaseCategoryResyncJob, :aggregate_failures, current_user_id: 1, performs_jobs: true do
  let(:knowledge_base)  { create(:knowledge_base) }
  let(:category)        { create(:knowledge_base_category, knowledge_base:) }
  let(:sub_category)    { create(:knowledge_base_category, knowledge_base:, parent: category) }
  let(:other_category)  { create(:knowledge_base_category, knowledge_base:) }
  let(:answer)          { create(:knowledge_base_answer, :published, category:) }
  let(:sub_answer)      { create(:knowledge_base_answer, :published, category: sub_category) }
  let(:outside_answer)  { create(:knowledge_base_answer, :published, category: other_category) }

  before do
    allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
    answer
    sub_answer
    outside_answer
    clear_jobs
  end

  it 'enqueues a reindex for every translation in the subtree' do
    described_class.perform_now(category)

    expect(VectorIndexJob).to have_been_enqueued.with('KnowledgeBase::Answer::Translation', answer.translations.first.id)
    expect(VectorIndexJob).to have_been_enqueued.with('KnowledgeBase::Answer::Translation', sub_answer.translations.first.id)
  end

  # The moved category is indexable — that is why the job ran at all — but a descendant of it can be
  # excluded in its own right, and reindexing those answers only ever removes them again.
  it 'leaves translations in an excluded sub-category alone' do
    Setting.set('vectordb_knowledge_base_excluded_category_ids', [sub_category.id])

    described_class.perform_now(category)

    expect(VectorIndexJob).to have_been_enqueued.with('KnowledgeBase::Answer::Translation', answer.translations.first.id)
    expect(VectorIndexJob).not_to have_been_enqueued.with('KnowledgeBase::Answer::Translation', sub_answer.translations.first.id)
  end

  it 'leaves translations outside the subtree alone' do
    described_class.perform_now(category)

    expect(VectorIndexJob).not_to have_been_enqueued.with('KnowledgeBase::Answer::Translation', outside_answer.translations.first.id)
  end

  it 'covers every translation of a multi-locale answer' do
    alternative_locale = create(:knowledge_base_locale, knowledge_base:, system_locale: Locale.find_by(locale: 'lt'))
    translation        = create(:knowledge_base_answer_translation, answer:, kb_locale: alternative_locale)
    clear_jobs

    described_class.perform_now(category)

    expect(VectorIndexJob).to have_been_enqueued.with('KnowledgeBase::Answer::Translation', translation.id)
  end

  # The vector database can be switched off between the move and the job running; the fan-out would
  # otherwise enqueue a reindex per translation with nothing to index into.
  it 'does not enqueue anything when the vector database is unavailable' do
    allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(false)

    described_class.perform_now(category)

    expect(VectorIndexJob).not_to have_been_enqueued
  end

  # The category can be destroyed between the move and the job running. Its argument then fails to
  # deserialize, which the job discards instead of letting the worker retry it.
  it 'discards itself when the category is gone' do
    gone_category = create(:knowledge_base_category, knowledge_base:)
    job_data      = described_class.new(gone_category).serialize
    gone_category.destroy!
    clear_jobs

    expect { ActiveJob::Base.execute(job_data) }.not_to raise_error
    expect(VectorIndexJob).not_to have_been_enqueued
  end
end
