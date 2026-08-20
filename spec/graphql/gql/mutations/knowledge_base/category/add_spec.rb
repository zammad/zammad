# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::KnowledgeBase::Category::Add, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseCategoryAdd($knowledgeBaseId: ID!, $input: KnowledgeBaseCategoryInput!, $locale: String!) {
        knowledgeBaseCategoryAdd(knowledgeBaseId: $knowledgeBaseId, input: $input, locale: $locale) {
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
  let(:variables)      { { knowledgeBaseId: gql.id(knowledge_base), input:, locale: }.compact }

  let(:created_category) { KnowledgeBase::Category.find(gql.result.data.dig('category', 'id').then { |id| Gql::ZammadSchema.internal_id_from_id(id) }) }

  before do
    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'creates a top level category' do
      expect(gql.result.data['category']).to include(
        'title'        => title,
        'categoryIcon' => category_icon,
        'parent'       => nil,
      )
    end

    context 'with a parent category' do
      let(:parent_id) { gql.id(category) }
      let(:setup)     { category }

      it 'creates the category below the given parent' do
        expect(gql.result.data.dig('category', 'parent')).to eq('id' => gql.id(category))
      end
    end

    context 'without an icon' do
      let(:category_icon) { nil }

      it 'falls back to the default icon of the knowledge base' do
        expect(gql.result.data['category']).to include('categoryIcon' => knowledge_base.default_category_icon)
      end
    end

    context 'without a title' do
      let(:title) { nil }

      it 'returns a user error' do
        expect(gql.result.data['errors']).to include(include('message' => 'A title is required.'))
      end

      it 'creates no category' do
        expect(KnowledgeBase::Category.count).to be_zero
      end
    end

    context 'with a title another sibling already uses' do
      let(:setup) { category }
      let(:title) { category.translation_primary.title }

      it 'returns a user error for the title field' do
        expect(gql.result.data['errors']).to include(include('field' => 'translations.title'))
      end
    end

    # Silently writing the title into another locale than the requested one would leave the client
    #   no way to tell where it ended up.
    context 'with a locale the knowledge base does not have' do
      let(:locale) { 'zh-cn' }

      it 'returns a user error' do
        expect(gql.result.data['errors']).to include(include('message' => 'The selected language does not belong to this knowledge base.'))
      end
    end

    context 'with a parent of another knowledge base' do
      let(:other_parent) { create(:knowledge_base_category) }
      let(:parent_id)    { gql.id(other_parent) }

      it 'returns a user error' do
        expect(gql.result.data['errors']).to include(include('message' => 'The selected parent category does not belong to this knowledge base.'))
      end
    end

    context 'with permissions' do
      let(:other_role)  { create(:role, permission_names: 'knowledge_base.reader') }
      let(:permissions) { [{ roleId: gql.id(other_role), access: 'none' }, { roleId: gql.id(editor_role), access: 'editor' }] }

      it 'applies them to the new category' do
        expect(created_category.permissions.map { |permission| [permission.role_id, permission.access] })
          .to include([other_role.id, 'none'], [editor_role.id, 'editor'])
      end
    end

    context 'with permissions that lock the current user out' do
      let(:permissions) { [{ roleId: gql.id(editor_role), access: 'reader' }] }

      # Named after the matrix, so the form can show it below the field instead of on the form.
      it 'returns a user error for the permissions field' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'These permissions are invalid because they would lock you out.', 'field' => 'permissions'))
      end

      it 'rolls the whole mutation back' do
        expect(KnowledgeBase::Category.count).to be_zero
      end
    end
  end

  context 'with a granular editor of one subtree' do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }

    # Reader on the knowledge base plus editor on one category — the only constructible granular
    #   setup, since KnowledgeBase::PermissionsUpdate lets a child override a 'reader' parent only.
    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: category, role: granular_role, access: 'editor')
    end

    context 'when creating below the permitted category', authenticated_as: :granular_editor do
      let(:parent_id) { gql.id(category) }

      it 'creates the category' do
        expect(gql.result.data.dig('category', 'parent')).to eq('id' => gql.id(category))
      end
    end

    context 'when creating at the top level', authenticated_as: :granular_editor do
      it 'raises an error' do
        expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
      end
    end

    # Refused by CategoryPolicy#create?, which asks the parent — the same check that refuses the top
    #   level above, hence the same error.
    context 'when creating below a category they only read', authenticated_as: :granular_editor do
      let(:parent_id) { gql.id(other_category) }

      it 'raises an error' do
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
