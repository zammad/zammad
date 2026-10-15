# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::KnowledgeBase::Answer::Suggestion::Content::Transform, current_user_id: 1, type: :graphql do
  context 'when fetching content', authenticated_as: :agent do
    let(:agent)    { create(:agent) }
    let(:customer) { create(:customer) }

    let(:knowledge_base_answer) { create(:knowledge_base_answer, :published, :with_image, :with_attachment) }
    let(:knowledge_base_answer_translation) { knowledge_base_answer.translation }

    let(:mutation) do
      <<~MUTATION
        mutation knowledgeBaseAnswerSuggestionContentTransform(
          $translationId: ID!
          $formId: FormId!
        ) {
          knowledgeBaseAnswerSuggestionContentTransform(
            translationId: $translationId
            formId: $formId
          ) {
            body
            attachments {
              id
              name
              size
              type
              preferences
            }
            errors {
              message
              field
            }
          }
        }
      MUTATION
    end

    let(:variables) { { translationId: Gql::ZammadSchema.id_from_object(knowledge_base_answer_translation), formId: '5570fac8-8868-40b7-89e7-1cdabbd954ba' } }

    before do
      gql.execute(mutation, variables: variables)
    end

    context 'with authenticated session' do
      let(:copied_attachments)          { Store.list(object: 'UploadCache', o_id: '5570fac8-8868-40b7-89e7-1cdabbd954ba') }
      let(:copied_inline_attachments)   { copied_attachments.select(&:inline?) }
      let(:copied_attached_attachments) { copied_attachments.reject(&:inline?) }

      it 'points inline images to the copied attachments' do
        expect(gql.result.data[:body]).to include("src=\"/api/v1/attachments/#{copied_inline_attachments.first.id}")
      end

      context 'with an embedded video' do
        let(:knowledge_base_answer) { create(:knowledge_base_answer, :published, :with_video) }

        it 'replaces the video marker with a link to the video', :aggregate_failures do
          expect(gql.result.data[:body]).to include("<a href='https://www.youtube.com/watch?v=vTTzwJsHpU8'>")
          expect(gql.result.data[:body]).not_to include('widget: video')
        end
      end

      it 'contains attachments' do
        attachment = copied_attached_attachments.first
        expect(gql.result.data[:attachments]).to match_array(include(
                                                               id:          Gql::ZammadSchema.id_from_object(attachment),
                                                               name:        attachment.filename,
                                                               size:        attachment.size.to_i,
                                                               type:        attachment.preferences['Content-Type'],
                                                               preferences: attachment.preferences,
                                                             ))
      end

      context 'with a link to another answer' do
        let(:target_translation)    { create(:knowledge_base_answer, :published).translation }
        let(:target_id)             { target_translation.id }
        let(:knowledge_base_answer) do
          create(:knowledge_base_answer, :published, translation_attributes: {
                   content: build(:knowledge_base_answer_translation_content, body: "<a href='/desktop/knowledge-base/locale/en-us/answer/1' data-target-type='knowledge-base-answer' data-target-id='#{target_id}'>See also</a>")
                 })
        end

        it 'turns the link into an ordinary one to the public answer page' do
          expect(gql.result.data[:body]).to eq("<a href=\"#{target_translation.public_url}\">See also</a>")
        end

        context 'when the target answer does not exist' do
          let(:target_id) { 0 }

          it 'replaces the link by its text', :aggregate_failures do
            expect(gql.result.data[:body]).to include('See also')
            expect(gql.result.data[:body]).not_to include('<a')
          end
        end

        context 'when the target answer is not public' do
          let(:agent_url) { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/desktop/knowledge-base/locale/en-us/answer/#{target_translation.answer_id}" }

          shared_examples 'linking to the answer in the desktop app' do
            it 'turns the link into an ordinary absolute one to the answer in the desktop app' do
              expect(gql.result.data[:body]).to eq("<a href=\"#{agent_url}\">See also</a>")
            end
          end

          context 'with an internal answer' do
            let(:target_translation) { create(:knowledge_base_answer, :internal).translation }

            it_behaves_like 'linking to the answer in the desktop app'
          end

          context 'with a draft answer' do
            let(:target_translation) { create(:knowledge_base_answer, :draft).translation }

            it_behaves_like 'linking to the answer in the desktop app'
          end

          context 'with an archived answer' do
            let(:target_translation) { create(:knowledge_base_answer, :published, :archived).translation }

            it_behaves_like 'linking to the answer in the desktop app'
          end

          context 'with a published answer of an inactive knowledge base' do
            let(:target_translation) do
              create(:knowledge_base_answer, :published, knowledge_base: create(:knowledge_base, active: false)).translation
            end

            it_behaves_like 'linking to the answer in the desktop app'
          end
        end
      end

      context 'with not existing translation' do
        let(:variables) { { translationId: Gql::ZammadSchema.id_from_object(knowledge_base_answer), formId: '5570fac8-8868-40b7-89e7-1cdabbd954ba' } }

        it 'raises an error' do
          expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'when agent has no KB category access to an internal answer', authenticated_as: :restricted_agent do
      let(:restricted_agent)               { create(:agent) }
      let(:internal_knowledge_base_answer) { create(:knowledge_base_answer, :internal, :with_image, :with_attachment) }
      let(:variables)                      { { translationId: Gql::ZammadSchema.id_from_object(internal_knowledge_base_answer.translation), formId: '5570fac8-8868-40b7-89e7-1cdabbd954ba' } }

      before do
        KnowledgeBase::PermissionsUpdate.new(internal_knowledge_base_answer.category).update!(restricted_agent.roles.first => 'none')
        gql.execute(mutation, variables: variables)
      end

      it 'raises a forbidden error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without proper permissions', authenticated_as: :admin do
      let(:admin) { create(:admin_only) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with a customer', authenticated_as: :customer do
      it 'fails with error type' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  # A standalone context (not nested under 'when fetching content') - that context's own
  #   `before` unconditionally executes the mutation once against an empty cache, which would
  #   already have cloned this same user's attachments into the cache by the time a nested
  #   `before` here seeded the intruder file, confounding the authorization check under test.
  context 'when form_id points to another users cache', authenticated_as: :agent do
    let(:agent)       { create(:agent) }
    let(:other_agent) { create(:agent) }

    let(:knowledge_base_answer)             { create(:knowledge_base_answer, :published, :with_image, :with_attachment) }
    let(:knowledge_base_answer_translation) { knowledge_base_answer.translation }
    let(:form_id)                           { '5570fac8-8868-40b7-89e7-1cdabbd954ba' }

    let(:mutation) do
      <<~MUTATION
        mutation knowledgeBaseAnswerSuggestionContentTransform(
          $translationId: ID!
          $formId: FormId!
        ) {
          knowledgeBaseAnswerSuggestionContentTransform(
            translationId: $translationId
            formId: $formId
          ) {
            body
            attachments {
              id
              name
              size
              type
              preferences
            }
            errors {
              message
              field
            }
          }
        }
      MUTATION
    end

    let(:variables) { { translationId: Gql::ZammadSchema.id_from_object(knowledge_base_answer_translation), formId: form_id } }

    before do
      UploadCache.new(form_id).add(
        filename:      'intruder.txt',
        data:          'Intruder content',
        preferences:   { 'Content-Type' => 'text/plain' },
        created_by_id: other_agent.id,
      )
      gql.execute(mutation, variables: variables)
    end

    it 'forbids cloning attachments into another users cache' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
