# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::KnowledgeBase::Update, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseUpdate($input: KnowledgeBaseInput!, $locale: String!) {
        knowledgeBaseUpdate(input: $input, locale: $locale) {
          knowledgeBase {
            id
            title
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:title)       { 'Renamed knowledge base' }
  let(:footer_note) { '© Renamed' }
  let(:permissions) { nil }
  let(:locale)      { primary_locale.system_locale.locale }
  let(:input)       { { title:, footerNote: footer_note, permissions: }.compact }
  let(:variables)   { { input:, locale: } }

  before do
    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'returns the updated knowledge base' do
      expect(gql.result.data['knowledgeBase']).to include('title' => title)
    end

    it 'updates the title and the footer note' do
      expect(knowledge_base.reload.translation_to(primary_locale))
        .to have_attributes(title:, footer_note:)
    end

    context 'with the footer note missing' do
      let(:input) { { title: } }

      it 'is rejected by the schema' do
        expect(gql.result.error_message).to include('footerNote')
      end
    end

    context 'with texts for one locale only' do
      let(:setup) do
        knowledge_base.translations.create!(kb_locale: alternative_locale, title: 'Kita žinių bazė', footer_note: '© Kita')
      end

      it 'keeps the texts of the locales that were not submitted' do
        expect(knowledge_base.reload.translation_to(alternative_locale).title).to eq('Kita žinių bazė')
      end
    end

    # `title` and `footer_note` are mandatory, so a permissions-only update no longer exists.
    context 'without any text' do
      let(:input) { { permissions: [{ roleId: gql.id(editor_role), access: 'editor' }] } }

      it 'is rejected by the schema' do
        expect(gql.result.error_message).to include('title')
      end
    end

    # A locale added after the knowledge base was created has no translation yet.
    context 'with a title for a locale that has no translation yet' do
      let(:locale) { alternative_locale.system_locale.locale }
      let(:setup)  { alternative_locale }

      it 'creates the translation' do
        expect(knowledge_base.reload.translation_to(alternative_locale))
          .to have_attributes(title:, footer_note:)
      end
    end

    # One locale per call: the submitted texts are written into it, and the payload — normalized
    #   straight into the client cache — comes back in it, so a client always sees what it wrote.
    context 'with another locale' do
      let(:locale) { alternative_locale.system_locale.locale }
      let(:setup)  { alternative_locale }

      it 'writes the texts into that locale', :aggregate_failures do
        expect(knowledge_base.reload.translation_to(alternative_locale)).to have_attributes(title:, footer_note:)
        expect(knowledge_base.reload.translation_to(primary_locale).title).not_to eq(title)
      end

      it 'returns the title in that locale' do
        expect(gql.result.data['knowledgeBase']).to include('title' => title)
      end
    end

    context 'with a locale the knowledge base does not have' do
      let(:locale) { 'zh-cn' }

      # Nothing else in this example refers to the knowledge base, which the shared context creates
      #   lazily — without this the mutation would not find one at all.
      let(:setup) { knowledge_base }

      it 'returns a user error' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'The selected language does not belong to this knowledge base.'))
      end
    end

    context 'with a blank title' do
      let(:title) { '  ' }

      it 'is rejected by the schema' do
        expect(gql.result.error_message).to include('is not a valid NonEmptyString')
      end
    end

    context 'with a blank footer note' do
      let(:footer_note) { '  ' }

      it 'is rejected by the schema' do
        expect(gql.result.error_message).to include('is not a valid NonEmptyString')
      end
    end

    context 'with permissions' do
      let(:other_role)  { create(:role, permission_names: 'knowledge_base.reader') }
      let(:permissions) { [{ roleId: gql.id(other_role), access: 'none' }, { roleId: gql.id(editor_role), access: 'editor' }] }

      it 'applies them to the knowledge base' do
        expect(knowledge_base.reload.permissions.map { |permission| [permission.role_id, permission.access] })
          .to include([other_role.id, 'none'], [editor_role.id, 'editor'])
      end
    end

    # The form offers the matrix before any permission exists, so saving it untouched must not be
    #   what switches the whole instance to granular permissions.
    context 'with permissions that only restate what the roles have anyway' do
      let(:other_role)  { create(:role, permission_names: 'knowledge_base.reader') }
      let(:permissions) { [{ roleId: gql.id(other_role), access: 'reader' }, { roleId: gql.id(editor_role), access: 'editor' }] }

      it 'stores none of them', :aggregate_failures do
        expect(knowledge_base.reload.permissions).to be_empty
        expect(KnowledgeBase).not_to be_granular_permissions
      end

      it 'still saves the rest of the form' do
        expect(knowledge_base.reload.translation_to(primary_locale).title).to eq(title)
      end

      context 'when granular permissions are already in use' do
        let(:setup) { create(:knowledge_base_permission, permissionable: knowledge_base, role: editor_role, access: 'editor') }

        it 'applies them like any other selection' do
          expect(knowledge_base.reload.permissions.map { |permission| [permission.role_id, permission.access] })
            .to include([other_role.id, 'reader'], [editor_role.id, 'editor'])
        end
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
        expect(knowledge_base.reload.translation_to(primary_locale).title).not_to eq(title)
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
