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

  # Both routes into the navigation take their sibling ids from Service::KnowledgeBase::Answers, so
  #   the neighbours follow the category's `answer_sorting_mode` — which the `position` order the
  #   examples above run in is not. Every example here creates its answers against the order it
  #   asserts, so a regression back to `position` fails them instead of reordering silently.
  describe 'with a sorting mode' do
    def answer_titled(title)
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title: })
    end

    context 'with the alphabetical mode' do
      let(:zulu)  { answer_titled('Zulu') }
      let(:mike)  { answer_titled('Mike') }
      let(:alpha) { answer_titled('Alpha') }

      # Created against their alphabetical order, so the positions the outer `before` hands out in
      #   creation order put every neighbour below on the opposite side.
      let(:answers) { [zulu, mike, alpha] }
      let(:answer)  { mike }

      before { category.update!(answer_sorting_mode: 'alphabetical') }

      it 'counts and navigates the siblings by title', :aggregate_failures do
        expect(result).to have_attributes(
          index:              2,
          total_count:        3,
          previous_answer_id: alpha.id,
          next_answer_id:     zulu.id,
        )
      end

      # The wrap is index arithmetic over the id list, so it moves with the order: both ends of the
      #   list are the alphabetical ones, not the hand-arranged ones.
      context 'when the answer is alphabetically first' do
        let(:answer) { alpha }

        it 'wraps the previous answer to the last sibling by title', :aggregate_failures do
          expect(result).to have_attributes(index: 1, previous_answer_id: zulu.id, next_answer_id: mike.id)
        end
      end

      context 'when the answer is alphabetically last' do
        let(:answer) { zulu }

        it 'wraps the next answer to the first sibling by title', :aggregate_failures do
          expect(result).to have_attributes(index: 3, previous_answer_id: mike.id, next_answer_id: alpha.id)
        end
      end
    end

    context 'with the last update mode' do
      let(:newest) { answer_titled('Newest') }
      let(:oldest) { answer_titled('Oldest') }
      let(:middle) { answer_titled('Middle') }

      # Created against the wanted order again: by position this reads newest, oldest, middle, so
      #   neither neighbour of `middle` is the one the edit dates give it.
      let(:answers) { [newest, oldest, middle] }
      let(:answer)  { middle }

      before do
        category.update!(answer_sorting_mode: 'last_update')

        travel_to(1.hour.from_now)  { middle.translation.update!(title: 'Middle, edited') }
        travel_to(2.hours.from_now) { newest.translation.update!(title: 'Newest, edited') }
      end

      it 'counts and navigates the siblings by edit date', :aggregate_failures do
        expect(result).to have_attributes(
          index:              2,
          total_count:        3,
          previous_answer_id: newest.id,
          next_answer_id:     oldest.id,
        )
      end

      context 'when the answer is the least recently edited' do
        let(:answer) { oldest }

        it 'wraps the next answer to the most recently edited sibling', :aggregate_failures do
          expect(result).to have_attributes(index: 3, previous_answer_id: middle.id, next_answer_id: newest.id)
        end
      end
    end
  end
end
