# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What an update does to the answer is Service::KnowledgeBase::Answer::Update's business and is
#   covered there. This is about the mutation around it: its permission gate, the answer it loads,
#   the locale it resolves, how the service's refusals reach the client, and what it renders back.
RSpec.describe Gql::Mutations::KnowledgeBase::Answer::Update, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:answer) do
    create(:knowledge_base_answer, category:, translation_attributes: { title: 'Stored title', kb_locale: primary_locale })
  end

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseAnswerUpdate($answerId: ID!, $input: KnowledgeBaseUpdateAnswerInput!, $locale: String!) {
        knowledgeBaseAnswerUpdate(answerId: $answerId, input: $input, locale: $locale) {
          answer {
            id
            translation { id title content { body } }
            category { id }
            visibility
            policy {
              update
              destroy
            }
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end

  let(:answer_id) { gql.id(answer) }
  let(:locale)    { primary_locale.system_locale.locale }
  let(:input)     { { title: 'New title' } }
  let(:variables) { { answerId: answer_id, input:, locale: } }

  before do
    answer

    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'returns the updated answer', :aggregate_failures do
      expect(gql.result.data['answer']).to include('id' => gql.id(answer))
      expect(gql.result.data.dig('answer', 'translation')).to include('title' => 'New title')
    end

    # Every attribute is optional, and the schema is what says so - a partial save must not be
    #   refused for the fields it leaves out.
    context 'with an empty input' do
      let(:input) { {} }

      it 'returns the answer unchanged' do
        expect(gql.result.data.dig('answer', 'translation', 'title')).to eq('Stored title')
      end
    end

    # The entry points gate on this rather than on the global `knowledge_base.editor` permission:
    #   granular permissions can leave the same user an editor of one subtree and a reader of the
    #   next.
    it 'returns what the current user may do with the answer' do
      expect(gql.result.data.dig('answer', 'policy')).to eq('update' => true, 'destroy' => true)
    end

    # The visibility argument has to reach the service as the state it names.
    context 'with a visibility' do
      let(:input) { { visibility: 'published' } }

      it 'applies it' do
        expect(gql.result.data.dig('answer', 'visibility')).to eq('published')
      end
    end

    context 'with a category' do
      let(:input) { { categoryId: gql.id(other_category) } }

      it 'moves the answer' do
        expect(gql.result.data.dig('answer', 'category')).to eq('id' => gql.id(other_category))
      end
    end

    # The payload is rendered in the locale that was written, not in the primary one: its
    #   locale-dependent fields go straight into the client cache.
    context 'with an alternative locale' do
      let(:locale) { alternative_locale.system_locale.locale }
      let(:input)  { { title: 'Alternative title', body: '<p>Alternative body</p>' } }

      it 'writes and renders the answer in that locale', :aggregate_failures do
        expect(gql.result.data.dig('answer', 'translation', 'title')).to eq('Alternative title')
        expect(gql.result.data.dig('answer', 'translation', 'content')).to eq('body' => '<p>Alternative body</p>')
        expect(answer.translation_to(primary_locale).title).to eq('Stored title')
      end
    end

    # Writing the title into another locale than the requested one would leave the client no way to
    #   tell where it ended up.
    context 'with a locale the knowledge base does not have' do
      let(:locale) { 'zh-cn' }

      it 'returns a user error' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'The selected language does not belong to this knowledge base.'))
      end
    end

    context 'with a blank title' do
      let(:input) { { title: '   ' } }

      it 'raises an error' do
        expect(gql.result.error_message).to include('invalid value for title ("   " is not a valid NonEmptyString)')
      end
    end

    # A model validation, not a service refusal: KnowledgeBase::HasUniqueTitle reports it on the
    #   answer's `translations.title` path, which is what the form has to map back onto its own
    #   `title` field.
    context 'with a title another answer in the category already has' do
      let(:setup) do
        create(:knowledge_base_answer, category:, translation_attributes: { title: 'New title', kb_locale: primary_locale })
      end

      it 'returns a user error naming the translation path' do
        expect(gql.result.data['errors'].first).to include('field' => 'translations.title')
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

    context 'when the answer is in the permitted category', authenticated_as: :granular_editor do
      it 'returns the updated answer' do
        expect(gql.result.data.dig('answer', 'translation', 'title')).to eq('New title')
      end
    end

    # Gated on the way in, by the argument that loads the answer - which is why this one is refused
    #   as a plain Forbidden rather than as the service's Pundit::NotAuthorizedError below.
    context 'when the answer is in a category they only read', authenticated_as: :granular_editor do
      let(:answer) { create(:knowledge_base_answer, category: other_category) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    # Nothing gates the category on the way in — where an answer may be filed is decided by the
    #   service, of the already reassigned answer.
    context 'when moving it into a category they only read', authenticated_as: :granular_editor do
      let(:input) { { categoryId: gql.id(other_category) } }

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
  # Saving replays the form's upload cache and deletes what is not in it, so a cache seeded before
  #   somebody else added a file would delete their file. The mutation reports that as a recognisable
  #   exception rather than going ahead, and the caller may resubmit with it skipped.
  describe 'a concurrent attachment change' do
    let(:form_id) { SecureRandom.uuid }

    let(:query) do
      <<~QUERY
        mutation knowledgeBaseAnswerUpdate($answerId: ID!, $input: KnowledgeBaseUpdateAnswerInput!, $locale: String!, $meta: KnowledgeBaseAnswerUpdateMetaInput) {
          knowledgeBaseAnswerUpdate(answerId: $answerId, input: $input, locale: $locale, meta: $meta) {
            answer { id translation { id title } }
            errors {
              message
              exception
            }
          }
        }
      QUERY
    end

    let(:input)     { { title: 'New title', formId: form_id } }
    let(:variables) { { answerId: answer_id, input:, locale:, meta: } }

    def setup
      UserInfo.with_user_id(editor.id) do
        Store.create!(object: 'KnowledgeBase::Answer', o_id: answer.id, data: 'theirs', filename: 'theirs.txt',
                      preferences: { 'Content-Type': 'text/plain' })
      end
    end

    context 'with an editor', authenticated_as: :editor do
      context 'when the form knew of no attachments' do
        let(:meta) { { knownAttachments: [] } }

        it 'refuses and names the exception', :aggregate_failures do
          expect(gql.result.data['answer']).to be_nil
          expect(gql.result.data['errors'].first).to include(
            'exception' => 'Service__KnowledgeBase__Answer__Update__Validator__ConcurrentAttachmentChange__Error',
          )
        end

        it 'leaves the answer alone' do
          expect(answer.reload.translations.first.title).to eq('Stored title')
        end
      end

      # The deliberate overwrite: resubmitting with the reported exception skipped.
      context 'when the caller overrides it' do
        let(:meta) do
          {
            knownAttachments: [],
            skipValidators:   ['Service__KnowledgeBase__Answer__Update__Validator__ConcurrentAttachmentChange__Error'],
          }
        end

        it 'saves' do
          expect(gql.result.data.dig('answer', 'translation')).to include('title' => 'New title')
        end
      end

      context 'when the form knew of their file' do
        let(:meta) { { knownAttachments: [{ name: 'theirs.txt', size: 6 }] } }

        it 'saves' do
          expect(gql.result.data.dig('answer', 'translation')).to include('title' => 'New title')
        end
      end
    end
  end
end
