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

  # The listing a visitor reaches an answer from is ordered by the mode of the node above it
  #   (KnowledgeBase::Public::BaseController#answers_filter / #categories_filter), so these links
  #   have to walk the same order — which the `position` order they used to walk is not.
  describe 'with a sorting mode' do
    def category_titled(title, parent: nil)
      create(:knowledge_base_category, knowledge_base:, parent:)
        .tap { |category| category.translations.first.update!(title:) }
    end

    def answer_titled(title, category:)
      create(:knowledge_base_answer, :published, category:, translation_attributes: { title: })
    end

    context 'with the alphabetical mode' do
      let(:sorted_parent) { category_titled('Sorted parent') }

      # Both levels are created against their alphabetical order, so a walk by `position` disagrees
      #   with the order the site renders — which is what these examples are about.
      let!(:yankee) { category_titled('Yankee', parent: sorted_parent) }
      let!(:bravo)  { category_titled('Bravo', parent: sorted_parent) }

      let!(:zulu)  { answer_titled('Zulu', category: bravo) }
      let!(:mike)  { answer_titled('Mike', category: bravo) }
      let!(:alpha) { answer_titled('Alpha', category: bravo) }

      let!(:yankee_answer) { answer_titled('Only answer', category: yankee) }

      before do
        sorted_parent.update!(category_sorting_mode: 'alphabetical')
        bravo.update!(answer_sorting_mode: 'alphabetical')
      end

      context 'when the answer is in between other answers' do
        let(:answer) { mike }

        it 'returns the next answer by title' do
          expect(adjacent_answer.next).to eq(zulu)
        end

        it 'returns the previous answer by title' do
          expect(adjacent_answer.previous).to eq(alpha)
        end
      end

      context 'when the answer is the last of its category by title' do
        let(:answer) { zulu }

        it 'enters the next sibling category by title' do
          expect(adjacent_answer.next).to eq(yankee_answer)
        end
      end

      # Both reversals at once: back into the sibling category the parent lists first, and to the
      #   answer that category lists last — each of them the mode's order reversed, not the
      #   positions'. By position `bravo` ends on its last-created answer, `alpha`. It is also the
      #   inverse of the step above, which is what makes the two links agree.
      context 'when the answer is the first of the tree by title' do
        let(:answer) { yankee_answer }

        it 'returns the last answer of the previous sibling category by title' do
          expect(adjacent_answer.previous).to eq(zulu)
        end
      end
    end

    # The top level is the one list whose mode is stored on the knowledge base rather than on a
    #   category, the way KnowledgeBase::Public::CategoriesController#index reads it.
    context 'with an alphabetically sorted top level' do
      # Created in reverse, so the hand-arranged order disagrees. One title being a prefix of the
      #   other, only a title extending that prefix can sort between them — which the factory's
      #   generated ones ("<appliance brand> #<n>") never do, so the tree above cannot wander in.
      let!(:root_second) { category_titled('Root Alpha Two') }
      let!(:root_first)  { category_titled('Root Alpha') }

      let!(:first_answer)  { answer_titled('Only answer', category: root_first) }
      let!(:second_answer) { answer_titled('Only answer', category: root_second) }

      before { knowledge_base.update!(category_sorting_mode: 'alphabetical') }

      context 'when the answer ends the alphabetically first top level category' do
        let(:answer) { first_answer }

        it 'enters the next top level category by title' do
          expect(adjacent_answer.next).to eq(second_answer)
        end
      end

      context 'when the answer starts the alphabetically second top level category' do
        let(:answer) { second_answer }

        it 'returns the last answer of the previous top level category by title' do
          expect(adjacent_answer.previous).to eq(first_answer)
        end
      end
    end

    context 'with the last update mode' do
      let(:sorted_category) { category_titled('Sorted') }

      # Created against the wanted order again: by position this reads newest, oldest, middle, so
      #   neither neighbour of `middle` is the one the edit dates give it.
      let!(:newest) { answer_titled('Newest', category: sorted_category) }
      let!(:oldest) { answer_titled('Oldest', category: sorted_category) }
      let!(:middle) { answer_titled('Middle', category: sorted_category) }

      before do
        sorted_category.update!(answer_sorting_mode: 'last_update')

        travel_to(1.hour.from_now)  { middle.translation.update!(title: 'Middle, edited') }
        travel_to(2.hours.from_now) { newest.translation.update!(title: 'Newest, edited') }
      end

      context 'when the answer is in between other answers' do
        let(:answer) { middle }

        it 'returns the answer edited before it' do
          expect(adjacent_answer.next).to eq(oldest)
        end

        it 'returns the answer edited after it' do
          expect(adjacent_answer.previous).to eq(newest)
        end
      end

      context 'when the answer is the least recently edited' do
        let(:answer) { oldest }

        it 'returns the answer edited after it' do
          expect(adjacent_answer.previous).to eq(middle)
        end
      end
    end
  end
end
