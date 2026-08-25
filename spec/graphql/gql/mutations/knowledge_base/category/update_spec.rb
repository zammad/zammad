# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What updating a category does — titles per locale, moving, permissions — is covered by
#   spec/services/service/knowledge_base/category/update_spec.rb. This covers the GraphQL surface
#   only: the argument gate, how the service's errors reach the client, and the payload.
RSpec.describe Gql::Mutations::KnowledgeBase::Category::Update, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseCategoryUpdate($categoryId: ID!, $input: KnowledgeBaseCategoryInput!, $locale: String!) {
        knowledgeBaseCategoryUpdate(categoryId: $categoryId, input: $input, locale: $locale) {
          category {
            id
            title
            categoryIcon
            position
            parent { id }
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
  let(:title)        { 'Renamed category' }
  let(:permissions)  { nil }
  let(:locale)       { primary_locale.system_locale.locale }
  # `parentId` has three states: absent (leave the parent alone), an explicit `null` (move to the top
  #   level) and an id (move there) — so it must never be built with `.compact`.
  let(:parent_input) { {} }
  let(:input)        { { title:, permissions: }.compact.merge(parent_input) }
  let(:variables)    { { categoryId: gql.id(record), input:, locale: } }

  before do
    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'returns the updated category' do
      expect(gql.result.data['category']).to include('title' => title)
    end

    context 'with an icon' do
      let(:input) { { categoryIcon: 'f1ad', title: } }

      it 'returns the updated icon' do
        expect(gql.result.data['category']).to include('categoryIcon' => 'f1ad')
      end
    end

    # The payload is normalized straight into the client cache, so its locale-dependent fields have
    #   to come back in the locale that was written, not in the primary one.
    context 'with another locale' do
      let(:locale) { alternative_locale.system_locale.locale }

      it 'returns the title in that locale' do
        expect(gql.result.data['category']).to include('title' => title)
      end
    end

    context 'with a locale the knowledge base does not have' do
      let(:locale) { 'zh-cn' }

      it 'returns a user error' do
        expect(gql.result.data['errors']).to include(include('message' => 'The selected language does not belong to this knowledge base.'))
      end
    end

    # The model validations, mapped to the attribute paths the record carries them under — the form
    #   relabels them onto its own fields.
    context 'with a title another sibling already uses' do
      let(:setup) { other_category }
      let(:title) { other_category.translation_primary.title }

      it 'returns a user error for the title field' do
        expect(gql.result.data['errors']).to include(include('field' => 'translations.title'))
      end
    end

    context 'when moving a category under its own descendant' do
      let(:parent_input) { { parentId: gql.id(subcategory) } }
      let(:setup)        { subcategory }

      it 'returns a user error for the parent field' do
        expect(gql.result.data['errors']).to include(include('field' => 'parent_id'))
      end
    end

    context 'with permissions that lock the current user out' do
      let(:permissions) { [{ roleId: gql.id(editor_role), access: 'reader' }] }

      # Named after the matrix, so the form can show it below the field instead of on the form.
      it 'returns a user error for the permissions field' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'These permissions are invalid because they would lock you out.', 'field' => 'permissions'))
      end
    end
  end

  # Two gates, two error types: the argument's Pundit gate refuses a category the user may not
  #   edit, while where it may be moved to is decided in the service.
  context 'with a granular editor of one subtree' do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }
    let(:record)          { subcategory }

    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: subcategory, role: granular_role, access: 'editor')
    end

    context 'when moving the category to the top level', authenticated_as: :granular_editor do
      let(:parent_input) { { parentId: nil } }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
      end
    end

    context 'when updating a category they only read', authenticated_as: :granular_editor do
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
