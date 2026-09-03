# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What clearing a schedule does to the answer is Service::KnowledgeBase::Answer::VisibilitySchedule
#   ::Remove's business and is covered there. This is about the mutation around it: its permission
#   gate, the answer it loads, and what it renders back - there is nothing for it to refuse, since
#   clearing a schedule that is not there is passed over quietly.
RSpec.describe Gql::Mutations::KnowledgeBase::Answer::VisibilitySchedule::Remove, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:scheduled) { 1.week.from_now.change(sec: 0) }

  let(:answer) do
    create(:knowledge_base_answer, category:, published_at: scheduled,
                                   translation_attributes: { title: 'Stored title', kb_locale: primary_locale })
  end

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseAnswerVisibilityScheduleRemove($answerId: ID!, $visibility: EnumKnowledgeBaseSchedulableVisibility!) {
        knowledgeBaseAnswerVisibilityScheduleRemove(answerId: $answerId, visibility: $visibility) {
          answer {
            id
            translation { id title }
            visibility
            visibilitySchedules {
              visibility
              scheduledAt
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

  let(:visibility) { 'published' }
  let(:variables)  { { answerId: gql.id(answer), visibility: } }

  before do
    answer

    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'returns the answer without the schedule', :aggregate_failures do
      expect(gql.result.data.dig('answer', 'id')).to eq(gql.id(answer))
      expect(gql.result.data.dig('answer', 'visibilitySchedules')).to be_empty
    end

    # The change never happens - it was not in effect, so the state the answer renders back is the
    #   one it already had.
    it 'leaves the rendered state alone' do
      expect(gql.result.data.dig('answer', 'visibility')).to eq('draft')
    end

    # No locale is asked of the caller, for the reason given on the add mutation - the answer is
    #   rendered in the current user's preferred locale, which here is the only one there is.
    it 'renders the answer in the preferred locale' do
      expect(gql.result.data.dig('answer', 'translation', 'title')).to eq('Stored title')
    end

    # The entry the client removes may not be there any more, which the service passes over quietly -
    #   so the client gets the answer back as it stands, not an error to show.
    context 'when the state is not scheduled' do
      let(:visibility) { 'archived' }

      it 'returns the answer with its remaining schedule', :aggregate_failures do
        expect(gql.result.data['errors']).to be_nil
        expect(gql.result.data.dig('answer', 'visibilitySchedules').sole)
          .to include('visibility' => 'published')
      end
    end

    # `draft` stores no date, so it is not among the states a scheduled change can be about.
    context 'with a state that stores no date' do
      let(:visibility) { 'draft' }

      it 'is refused by the schema' do
        expect(gql.result.error_message).to include('Variable $visibility of type EnumKnowledgeBaseSchedulableVisibility! was provided invalid value')
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
      it 'clears the schedule' do
        expect(gql.result.data.dig('answer', 'visibilitySchedules')).to be_empty
      end
    end

    # Gated on the way in, by the argument that loads the answer.
    context 'when the answer is in a category they only read', authenticated_as: :granular_editor do
      let(:answer) do
        create(:knowledge_base_answer, category: other_category, published_at: scheduled)
      end

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
