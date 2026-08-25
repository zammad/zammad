# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What the update itself does to the knowledge base is covered by
#   spec/services/service/knowledge_base/update_spec.rb — this covers the GraphQL surface only:
#   schema, authorization, how the service's errors reach the client, and the payload.
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

    # The payload is normalized straight into the client cache, so it has to come back in the
    #   locale that was written, not in the primary one.
    context 'with another locale' do
      let(:locale) { alternative_locale.system_locale.locale }
      let(:setup)  { alternative_locale }

      it 'returns the title in that locale' do
        expect(gql.result.data['knowledgeBase']).to include('title' => title)
      end
    end

    context 'with the footer note missing' do
      let(:input) { { title: } }

      it 'is rejected by the schema' do
        expect(gql.result.error_message).to include('footerNote')
      end
    end

    # `title` and `footer_note` are mandatory, so a permissions-only update no longer exists.
    context 'without any text' do
      let(:input) { { permissions: [{ roleId: gql.id(editor_role), access: 'editor' }] } }

      it 'is rejected by the schema' do
        expect(gql.result.error_message).to include('title')
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

    context 'with permissions that lock the current user out' do
      let(:permissions) { [{ roleId: gql.id(editor_role), access: 'reader' }] }

      # Named after the matrix, so the form can show it below the field instead of on the form.
      it 'returns a user error for the permissions field' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'These permissions are invalid because they would lock you out.', 'field' => 'permissions'))
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
