# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What is stored, and which orders are refused, is Service::KnowledgeBase::Reorder::Answers' business
#   and is covered in spec/services/service/knowledge_base/reorder/answers_spec.rb. This covers the
#   mutation around it: the category it loads and gates, the answers it accepts, and what it renders
#   back.
RSpec.describe Gql::Mutations::KnowledgeBase::Reorder::Answers, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:first)  { create(:knowledge_base_answer, category:, position: 0) }
  let(:second) { create(:knowledge_base_answer, category:, position: 1) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseReorderAnswers($categoryId: ID!, $sortingMode: EnumKnowledgeBaseSortingMode!, $answerIds: [ID!]) {
        knowledgeBaseReorderAnswers(categoryId: $categoryId, sortingMode: $sortingMode, answerIds: $answerIds) {
          category {
            id
            translation { title }
            answerSortingMode
            categorySortingMode
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:record)       { category }
  let(:sorting_mode) { 'last_update' }
  let(:answer_ids)   { nil }
  let(:variables)    { { categoryId: gql.id(record), sortingMode: sorting_mode, answerIds: answer_ids }.compact }

  before do
    first && second

    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    # The mode of the answers is stored on the category, so the category is what comes back.
    it 'returns the category with the stored mode' do
      expect(gql.result.data['category']).to include(
        'id'                => gql.id(category),
        'answerSortingMode' => 'last_update',
      )
    end

    # The category's two lists have a mode each, so ordering its answers leaves the order of its
    #   subcategories as it was — the combination a single column could not express.
    it 'leaves the mode of that category\'s subcategories alone' do
      expect(gql.result.data.dig('category', 'categorySortingMode')).to eq('manual')
    end

    it 'renders the category in the preferred locale' do
      expect(gql.result.data.dig('category', 'translation', 'title')).to eq(category.translation_to(primary_locale).title)
    end

    context 'with a hand-made order' do
      let(:sorting_mode) { 'manual' }
      let(:answer_ids)   { [gql.id(second), gql.id(first)] }

      it 'hands the submitted order to the service, in the order it was sent' do
        expect([first, second].map { |record| record.reload.position }).to eq([1, 0])
      end
    end

    context 'with a hand-made order against an automatic mode' do
      let(:answer_ids) { [gql.id(second), gql.id(first)] }

      it 'returns a user error', :aggregate_failures do
        expect(gql.result.data.dig('errors', 0, 'message')).to include('sorting mode is manual')
        expect(gql.result.data['category']).to be_nil
      end
    end

    context 'with an incomplete order' do
      let(:sorting_mode) { 'manual' }
      let(:answer_ids)   { [gql.id(first)] }

      it 'returns a user error' do
        expect(gql.result.data.dig('errors', 0, 'message')).to include('all items in scope')
      end
    end

    # `acts_as_list` is scoped to `category`, so an answer filed elsewhere is not part of the list
    #   this mutation numbers. The ids are not loaded here, so the scope check is what catches it.
    context 'with an answer of another category' do
      let(:sorting_mode) { 'manual' }
      let(:answer_ids)   { [gql.id(second), gql.id(first), gql.id(published_answer_in_other_category)] }

      it 'returns a user error' do
        expect(gql.result.data.dig('errors', 0, 'message')).to include('all items in scope')
      end
    end
  end

  context 'with a granular editor of one subtree' do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }

    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: category, role: granular_role, access: 'editor')
    end

    context 'with a category they may edit', authenticated_as: :granular_editor do
      it 'stores the mode' do
        expect(gql.result.data.dig('category', 'answerSortingMode')).to eq('last_update')
      end
    end

    # Gated on the way in, by the argument that loads the category.
    context 'with a category they only read', authenticated_as: :granular_editor do
      let(:record) { other_category }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'with a reader', authenticated_as: :reader do
    let(:reader) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }

    it 'raises an error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
