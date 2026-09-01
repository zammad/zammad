# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The gating fields the browse grid and the category action menus need outside of any form.
RSpec.describe Gql::Types::KnowledgeBase::CategoryType, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:query) do
    <<~GQL
      query knowledgeBaseCategorySubcategories($categoryId: ID) {
        knowledgeBaseCategorySubcategories(categoryId: $categoryId) {
          category {
            isDeletable
            policy {
              update
              destroy
              createSubcategory
              createAnswer
              destroyAnswer
              updateAnswer
              permissions
            }
          }
          subcategories {
            id
            isDeletable
          }
        }
      }
    GQL
  end

  let(:record)    { category }
  let(:variables) { { categoryId: gql.id(record) } }

  def category_result
    gql.result.data['category']
  end

  before do
    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    let(:editor) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.editor')]) }

    it 'allows every action' do
      expect(category_result['policy']).to include(
        'update'            => true,
        'destroy'           => true,
        'createSubcategory' => true,
        'createAnswer'      => true,
        'destroyAnswer'     => true,
        'updateAnswer'      => true,
        'permissions'       => true,
      )
    end

    it 'reports an empty category as deletable' do
      expect(category_result).to include('isDeletable' => true)
    end

    context 'with an answer in the category' do
      let(:setup) { draft_answer }

      # `directAnswerCount` cannot answer this: it counts what the current user may see, so it can
      #   read 0 for a category `destroy!` still refuses to delete.
      it 'reports the category as not deletable' do
        expect(category_result).to include('isDeletable' => false)
      end
    end

    context 'with a subcategory' do
      let(:setup) { subcategory }

      it 'reports the category as not deletable' do
        expect(category_result).to include('isDeletable' => false)
      end

      it 'reports the empty subcategory as deletable' do
        expect(gql.result.data['subcategories']).to contain_exactly(include('isDeletable' => true))
      end

      context 'when the subcategory holds an answer' do
        let(:setup) { create(:knowledge_base_answer, category: subcategory) }

        it 'reports the listed subcategory as not deletable' do
          expect(gql.result.data['subcategories']).to contain_exactly(include('isDeletable' => false))
        end
      end
    end
  end

  context 'with a granular editor whose access to the category and to its parent differ', authenticated_as: :granular_editor do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }
    let(:record)          { subcategory }

    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: subcategory, role: granular_role, access: 'editor')
    end

    it 'allows editing it and adding below it, but not removing it' do
      expect(category_result['policy']).to include(
        'update'            => true,
        'createSubcategory' => true,
        'createAnswer'      => true,
        # Acting on the answers *in* this category asks about the category itself, which they are
        #   editor of — unlike `destroy` below.
        'destroyAnswer'     => true,
        'updateAnswer'      => true,
        'permissions'       => true,
        # Removing a category changes what its parent contains, and the parent is reader-only here.
        'destroy'           => false,
      )
    end
  end

  context 'with a reader', authenticated_as: :reader do
    let(:reader) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.reader')]) }
    let(:record) { other_category }
    let(:setup)  { internal_answer_in_other_category }

    it 'allows no action' do
      expect(category_result['policy']).to include(
        'update'            => false,
        'destroy'           => false,
        'createSubcategory' => false,
        'createAnswer'      => false,
        'destroyAnswer'     => false,
        'updateAnswer'      => false,
        'permissions'       => false,
      )
    end

    # The reader path through the batched details, which resolves deletability from a different
    #   visibility branch than the editor one above.
    it 'reports the category as not deletable' do
      expect(category_result).to include('isDeletable' => false)
    end
  end
end
