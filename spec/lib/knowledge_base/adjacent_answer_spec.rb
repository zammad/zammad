# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe KnowledgeBase::AdjacentAnswer do
  subject(:adjacent_answer) { described_class.new(translation, user:) }

  let(:user)           { nil }
  let(:translation)    { answer.translations.first }
  let(:kb_locale)      { translation.answer.knowledge_base.locales.first }
  let(:knowledge_base) { create(:knowledge_base) }
  let(:category_a)     { create(:knowledge_base_category, knowledge_base:) }
  let(:category_a_1)   { create(:knowledge_base_category, knowledge_base:, parent: category_a) }
  let(:category_a_2)   { create(:knowledge_base_category, knowledge_base:, parent: category_a) }
  let(:category_a_1_1) { create(:knowledge_base_category, knowledge_base:, parent: category_a_1) }
  let(:category_a_1_2) { create(:knowledge_base_category, knowledge_base:, parent: category_a_1) }
  let(:category_b)     { create(:knowledge_base_category, knowledge_base:) }
  let(:category_b_1)   { create(:knowledge_base_category, knowledge_base:, parent: category_b) }
  let(:category_b_2)   { create(:knowledge_base_category, knowledge_base:, parent: category_b) }
  let(:category_b_2_1) { create(:knowledge_base_category, knowledge_base:, parent: category_b_2) }
  let(:category_c)     { create(:knowledge_base_category, knowledge_base:) }
  let(:category_c_1)   { create(:knowledge_base_category, knowledge_base:, parent: category_c) }

  let(:answer_a_first)      { create(:knowledge_base_answer, :published, category: category_a) }
  let(:answer_a_second)     { create(:knowledge_base_answer, :published, category: category_a) }
  let(:answer_a_1_1_first)  { create(:knowledge_base_answer, :published, category: category_a_1_1) }
  let(:answer_a_1_1_second) { create(:knowledge_base_answer, :published, category: category_a_1_1) }
  let(:answer_a_1_1_third)  { create(:knowledge_base_answer, :published, category: category_a_1_1) }
  let(:answer_a_1_2_first)  { create(:knowledge_base_answer, :published, category: category_a_1_2) }
  let(:answer_a_2_first)    { create(:knowledge_base_answer, :published, category: category_a_2) }
  let(:answer_b_2_1_first)  { create(:knowledge_base_answer, :published, category: category_b_2_1) }
  let(:answer_b_2_first)    { create(:knowledge_base_answer, :published, category: category_b_2) }
  let(:answer_b_2_second)   { create(:knowledge_base_answer, :published, category: category_b_2) }
  let(:answer_c_first)      { create(:knowledge_base_answer, :published, category: category_c) }
  let(:answer_c_1_first)    { create(:knowledge_base_answer, :published, category: category_c_1) }

  before do
    category_a
    category_a_1
    category_a_2
    category_a_1_1
    category_a_1_2
    category_b
    category_b_1
    category_b_2
    category_b_2_1
    category_c
    category_c_1

    answer_a_first
    answer_a_second
    answer_a_2_first
    answer_a_1_1_first
    answer_a_1_1_second
    answer_a_1_1_third
    answer_a_1_2_first
    answer_b_2_1_first
    answer_b_2_first
    answer_b_2_second
    answer_c_first
    answer_c_1_first
  end

  describe '#next' do
    shared_examples 'basic next examples' do
      context 'when the answer is in between other answers' do
        let(:answer) { answer_a_1_1_second }

        it 'returns the next answer in the same category' do
          expect(adjacent_answer.next).to eq(answer_a_1_1_third)
        end
      end

      context 'when the answer is the last answer in the category' do
        let(:answer) { answer_a_1_1_third }

        it 'returns the first answer in the next sibling category' do
          expect(adjacent_answer.next).to eq(answer_a_1_2_first)
        end
      end

      context 'when the answer is the first answer in the category' do
        let(:answer) { answer_a_1_1_first }

        it 'returns the next answer in the same category' do
          expect(adjacent_answer.next).to eq(answer_a_1_1_second)
        end
      end

      context 'when the answer is the last answer in the current tree' do
        let(:answer) { answer_b_2_second }

        it 'returns the first answer in the next category in the tree' do
          expect(adjacent_answer.next).to eq(answer_c_1_first)
        end
      end

      context 'when the answer is the last answer in the knowledge base' do
        let(:answer) { answer_c_first }

        it 'returns nil' do
          expect(adjacent_answer.next).to be_nil
        end
      end

      context 'when the answer is the last answer in the category but subcategories have answers' do
        let(:answer) { answer_b_2_second }

        it 'returns the first in next tree' do
          expect(adjacent_answer.next).to eq(answer_c_1_first)
        end
      end

      context 'when the answer is the last answer in a child subtree and parent has answers' do
        let(:answer) { answer_b_2_1_first }

        it 'returns the first answer in the parent category' do
          expect(adjacent_answer.next).to eq(answer_b_2_first)
        end
      end
    end

    shared_examples 'non-published next examples' do |visible:|
      let(:answer_a_1_1_second) { create(:knowledge_base_answer, :draft, category: category_a_1_1) }
      let(:answer_b_2_1_first)  { create(:knowledge_base_answer, :internal, category: category_b_2_1) }

      context 'when the next answer is not published' do
        let(:answer) { answer_a_1_1_first }

        it 'returns the expected answer' do
          expect(adjacent_answer.next).to eq(visible ? answer_a_1_1_second : answer_a_1_1_third)
        end
      end

      context 'when the next answer in another tree is not published' do
        let(:answer) { answer_a_second }

        it 'returns the expected answer' do
          expect(adjacent_answer.next).to eq(visible ? answer_b_2_1_first : answer_b_2_first)
        end
      end
    end

    context 'when user is a guest' do
      include_examples 'basic next examples'

      context 'when some answers are not published' do
        include_examples 'non-published next examples', visible: false
      end
    end

    context 'when user is a KB reader' do
      let(:user) { create(:agent) }

      include_examples 'basic next examples'

      context 'when some answers are not published' do
        include_examples 'non-published next examples', visible: false
      end
    end

    context 'when user is a KB editor' do
      let(:user) { create(:admin) }

      include_examples 'basic next examples'

      context 'when some answers are not published' do
        include_examples 'non-published next examples', visible: true
      end
    end
  end

  describe '#previous' do
    shared_examples 'basic previous examples' do
      context 'when the answer is in between other answers' do
        let(:answer) { answer_a_1_1_second }

        it 'returns the previous answer in the same category' do
          expect(adjacent_answer.previous).to eq(answer_a_1_1_first)
        end
      end

      context 'when the answer is the last answer in the category' do
        let(:answer) { answer_a_1_2_first }

        it 'returns the last answer in the previous sibling category' do
          expect(adjacent_answer.previous).to eq(answer_a_1_1_third)
        end
      end

      context 'when the answer is the first answer in the current tree' do
        let(:answer) { answer_b_2_1_first }

        it 'returns the last answer in the next category in the tree' do
          expect(adjacent_answer.previous).to eq(answer_a_second)
        end
      end

      context 'when the answer is the first answer in the knowledge base' do
        let(:answer) { answer_a_1_1_first }

        it 'returns nil' do
          expect(adjacent_answer.previous).to be_nil
        end
      end

      context 'when the answer is the first answer in parent and a subtree has as an answer' do
        let(:answer) { answer_b_2_first }

        it 'returns the first answer in the parent category' do
          expect(adjacent_answer.previous).to eq(answer_b_2_1_first)
        end
      end
    end

    shared_examples 'non-published previous examples' do |visible:|
      let(:answer_a_1_1_second) { create(:knowledge_base_answer, :draft, category: category_a_1_1) }
      let(:answer_b_2_1_first)  { create(:knowledge_base_answer, :internal, category: category_b_2_1) }

      context 'when the previous answer is not published' do
        let(:answer) { answer_a_1_1_third }

        it 'returns the expected answer' do
          expect(adjacent_answer.previous).to eq(visible ? answer_a_1_1_second : answer_a_1_1_first)
        end
      end

      context 'when the previous answer in another tree is not published' do
        let(:answer) { answer_b_2_first }

        it 'returns the expected answer' do
          expect(adjacent_answer.previous).to eq(visible ? answer_b_2_1_first : answer_a_second)
        end
      end
    end

    context 'when user is a guest' do
      include_examples 'basic previous examples'

      context 'when some answers are not published' do
        include_examples 'non-published previous examples', visible: false
      end
    end

    context 'when user is a KB reader' do
      let(:user) { create(:agent) }

      include_examples 'basic previous examples'

      context 'when some answers are not published' do
        include_examples 'non-published previous examples', visible: false
      end
    end

    context 'when user is a KB editor' do
      let(:user) { create(:admin) }

      include_examples 'basic previous examples'

      context 'when some answers are not published' do
        include_examples 'non-published previous examples', visible: true
      end
    end
  end
end
