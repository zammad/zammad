# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What creating a category does is covered by
#   spec/services/service/knowledge_base/category/create_spec.rb — this covers the GraphQL surface
#   only: schema, authorization, how the service's errors reach the client, and the payload.
RSpec.describe Gql::Mutations::KnowledgeBase::Category::Add, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseCategoryAdd($input: KnowledgeBaseCategoryInput!, $locale: String!) {
        knowledgeBaseCategoryAdd(input: $input, locale: $locale) {
          category {
            id
            title
            categoryIcon
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

  let(:title)          { 'Fresh category' }
  let(:category_icon)  { 'f1ad' }
  let(:permissions)    { nil }
  let(:parent_id)      { nil }
  let(:locale)         { primary_locale.system_locale.locale }
  let(:input)          { { categoryIcon: category_icon, title:, parentId: parent_id, permissions: }.compact }
  let(:variables)      { { input:, locale: }.compact }

  before do
    # Nothing in the variables refers to the knowledge base, which the shared context creates
    #   lazily — without this the mutation would not find one at all.
    knowledge_base

    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'returns the created category' do
      expect(gql.result.data['category']).to include(
        'title'        => title,
        'categoryIcon' => category_icon,
        'parent'       => nil,
      )
    end

    context 'with a parent category' do
      let(:parent_id) { gql.id(category) }
      let(:setup)     { category }

      it 'returns it as the parent' do
        expect(gql.result.data.dig('category', 'parent')).to eq('id' => gql.id(category))
      end
    end

    # The payload is normalized straight into the client cache, so its locale-dependent fields have
    #   to come back in the locale that was written.
    context 'with another locale' do
      let(:locale) { alternative_locale.system_locale.locale }
      let(:setup)  { alternative_locale }

      it 'returns the title in that locale' do
        expect(gql.result.data['category']).to include('title' => title)
      end
    end

    context 'without a title' do
      let(:title) { nil }

      it 'returns a user error' do
        expect(gql.result.data['errors']).to include(include('message' => 'A title is required.'))
      end
    end

    # The sibling title uniqueness of the model, mapped to the attribute path the record carries it
    #   under — the form relabels it onto its own title field.
    context 'with a title another sibling already uses' do
      let(:setup) { category }
      let(:title) { category.translation_primary.title }

      it 'returns a user error for the title field' do
        expect(gql.result.data['errors']).to include(include('field' => 'translations.title'))
      end
    end

    context 'with a locale the knowledge base does not have' do
      let(:locale) { 'zh-cn' }

      it 'returns a user error' do
        expect(gql.result.data['errors']).to include(include('message' => 'The selected language does not belong to this knowledge base.'))
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

    # Where a category may be created is decided per record in the service, so the mutation only
    #   has to let that refusal through.
    context 'when creating where the user has no editor access' do
      let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
      let(:granular_editor) { create(:user, roles: [granular_role]) }
      let(:setup)           { create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader') }

      it 'raises an error', authenticated_as: :granular_editor do
        expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
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
