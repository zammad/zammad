# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

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
    it 'updates the title' do
      expect(gql.result.data['category']).to include('title' => title)
    end

    context 'without a submitted parent' do
      let(:record) { subcategory }
      let(:setup) { subcategory }

      it 'leaves the parent alone' do
        expect(record.reload.parent_id).to eq(category.id)
      end
    end

    context 'with an icon' do
      let(:input) { { categoryIcon: 'f1ad', title: } }

      it 'updates the icon' do
        expect(gql.result.data['category']).to include('categoryIcon' => 'f1ad')
      end
    end

    context 'with a title for one locale only' do
      let(:setup) do
        record.translations.create!(kb_locale: alternative_locale, title: 'Kita kalba')
      end

      it 'keeps the titles of the locales that were not submitted' do
        expect(record.reload.translation_to(alternative_locale).title).to eq('Kita kalba')
      end
    end

    # One locale per call: the submitted title is written into it, and the payload — normalized
    #   straight into the client cache — comes back in it, so a client always sees what it wrote.
    context 'with another locale' do
      let(:locale) { alternative_locale.system_locale.locale }

      it 'writes the title into that locale', :aggregate_failures do
        expect(record.reload.translation_to(alternative_locale).title).to eq(title)
        expect(record.reload.translation_to(primary_locale).title).not_to eq(title)
      end

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

    context 'with a title another sibling already uses' do
      let(:setup) { other_category }
      let(:title) { other_category.translation_primary.title }

      it 'returns a user error for the title field' do
        expect(gql.result.data['errors']).to include(include('field' => 'translations.title'))
      end
    end

    context 'when moving to another parent' do
      let(:record)          { other_category }
      let(:target)          { create(:knowledge_base_category, knowledge_base:) }
      let(:parent_input)    { { parentId: gql.id(target) } }
      let(:setup)           { create_list(:knowledge_base_category, 2, knowledge_base:, parent: target) }

      it 'moves the category and appends it to its new siblings' do
        expect(record.reload).to have_attributes(parent_id: target.id, position: 2)
      end
    end

    context 'when moving to another parent that has a child of the same title' do
      let(:record)          { other_category }
      let(:target)          { create(:knowledge_base_category, knowledge_base:) }
      let(:parent_input)    { { parentId: gql.id(target) } }
      let(:setup)           { create(:knowledge_base_category, knowledge_base:, parent: target, translations: [build(:'knowledge_base/category/translation', title:, kb_locale: primary_locale)]) }

      # Only a single save can catch this: sibling uniqueness is scoped through the category's
      #   `parent_id`, so the new title has to be validated against the siblings at the new place.
      it 'returns a user error for the title field' do
        expect(gql.result.data['errors']).to include(include('field' => 'translations.title'))
      end

      it 'moves nothing' do
        expect(record.reload.parent_id).to be_nil
      end
    end

    context 'when moving to the top level with an explicit null' do
      let(:record)          { subcategory }
      let(:parent_input) { { parentId: nil } }
      let(:setup)        { subcategory }

      it 'moves the category to the top level' do
        expect(record.reload).to have_attributes(parent_id: nil, position: 1)
      end
    end

    context 'when moving a category under its own descendant' do
      let(:parent_input) { { parentId: gql.id(subcategory) } }
      let(:setup) { subcategory }

      it 'returns a user error for the parent field' do
        expect(gql.result.data['errors']).to include(include('field' => 'parent_id'))
      end
    end

    context 'when the move would exceed the allowed nesting depth' do
      let(:record)          { other_category }
      let(:target)          { create(:knowledge_base_category, knowledge_base:) }
      let(:parent_input)    { { parentId: gql.id(target) } }

      # Arranged as `setup` so it is in place before the mutation runs, and after the fixtures of the
      #   shared context have been created at their real depth.
      let(:setup) do
        target
        allow(KnowledgeBase::Category).to receive(:max_depth).and_return(1)
      end

      it 'returns a user error for the parent field' do
        expect(gql.result.data['errors'])
          .to include(include('field' => 'parent_id', 'message' => 'This field would exceed the allowed nesting depth'))
      end
    end

    context 'with permissions' do
      let(:other_role)  { create(:role, permission_names: 'knowledge_base.reader') }
      let(:permissions) { [{ roleId: gql.id(other_role), access: 'none' }, { roleId: gql.id(editor_role), access: 'editor' }] }

      it 'applies them to the category' do
        expect(record.reload.permissions.map { |permission| [permission.role_id, permission.access] })
          .to include([other_role.id, 'none'], [editor_role.id, 'editor'])
      end
    end

    context 'with permissions that lock the current user out' do
      let(:permissions) { [{ roleId: gql.id(editor_role), access: 'reader' }] }

      # Named after the matrix, so the form can show it below the field instead of on the form.
      it 'returns a user error for the permissions field' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'Invalid permissions, do not lock yourself out.', 'field' => 'permissions'))
      end

      it 'rolls the whole mutation back, including the title' do
        expect(record.reload.translation_primary.title).not_to eq(title)
      end
    end
  end

  context 'with a granular editor of one subtree' do
    let(:granular_role)   { create(:role, permission_names: 'knowledge_base.editor') }
    let(:granular_editor) { create(:user, roles: [granular_role]) }
    let(:record)          { subcategory }

    # Editor on the subcategory, only reader on its parent — the case the edit form is built for: it
    #   sends the stored parent back on every save even when that parent is not a permitted target.
    let(:setup) do
      create(:knowledge_base_permission, permissionable: knowledge_base, role: granular_role, access: 'reader')
      create(:knowledge_base_permission, permissionable: subcategory, role: granular_role, access: 'editor')
    end

    context 'when resubmitting the unchanged parent', authenticated_as: :granular_editor do
      let(:parent_input) { { parentId: gql.id(category) } }

      it 'updates the category' do
        expect(gql.result.data['category']).to include('title' => title)
      end
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
