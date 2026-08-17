# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::KnowledgeBase::AnswerNavigation do
  subject(:result) do
    described_class.with_current_user(user).execute(answer:, locale: primary_locale)
  end

  include_context 'basic Knowledge Base'

  let(:user) { create(:customer) }
  let(:answers) do
    Array.new(3) { create(:knowledge_base_answer, :published, category:) }
  end
  let(:answer) { answers[1] }

  before do
    answers.each.with_index(1) { |sibling, position| sibling.update_column(:position, position) }
  end

  it 'returns the answer position, total and siblings in listing order', :aggregate_failures do
    expect(result).to have_attributes(
      index:              2,
      total_count:        3,
      previous_answer_id: answers[0].id,
      next_answer_id:     answers[2].id,
    )
  end

  context 'when the answer is first' do
    let(:answer) { answers[0] }

    it 'wraps the previous answer to the last sibling', :aggregate_failures do
      expect(result).to have_attributes(previous_answer_id: answers[2].id, next_answer_id: answers[1].id)
    end
  end

  context 'when the answer is last' do
    let(:answer) { answers[2] }

    it 'wraps the next answer to the first sibling', :aggregate_failures do
      expect(result).to have_attributes(previous_answer_id: answers[1].id, next_answer_id: answers[0].id)
    end
  end

  context 'with one visible answer' do
    let(:answers) { [create(:knowledge_base_answer, :published, category:)] }
    let(:answer)  { answers[0] }

    it 'points both siblings at itself', :aggregate_failures do
      expect(result).to have_attributes(
        index:              1,
        total_count:        1,
        previous_answer_id: answer.id,
        next_answer_id:     answer.id,
      )
    end
  end

  context 'with an unpublished answer between published siblings' do
    let(:answers) do
      [
        create(:knowledge_base_answer, :published, category:),
        create(:knowledge_base_answer, category:),
        create(:knowledge_base_answer, :published, category:),
        create(:knowledge_base_answer, :published, category:),
      ]
    end
    let(:answer) { answers[2] }

    it 'does not count it for a public user', :aggregate_failures do
      expect(result).to have_attributes(
        index:              2,
        total_count:        3,
        previous_answer_id: answers[0].id,
        next_answer_id:     answers[3].id,
      )
    end

    context 'with an editor' do
      let(:user) { create(:admin) }

      it 'counts it in the visible listing order', :aggregate_failures do
        expect(result).to have_attributes(
          index:              3,
          total_count:        4,
          previous_answer_id: answers[1].id,
          next_answer_id:     answers[3].id,
        )
      end
    end
  end
end
