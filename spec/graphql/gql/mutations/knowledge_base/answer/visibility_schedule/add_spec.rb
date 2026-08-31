# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What a schedule does to the answer is Service::KnowledgeBase::Answer::VisibilitySchedule::Add's
#   business and is covered there. This is about the mutation around it: its permission gate, the
#   answer it loads, how the service's refusals reach the client, and what it renders back.
RSpec.describe Gql::Mutations::KnowledgeBase::Answer::VisibilitySchedule::Add, type: :graphql do
  include_context 'basic Knowledge Base'

  let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
  let(:editor)      { create(:user, roles: [editor_role]) }

  let(:answer) do
    create(:knowledge_base_answer, category:, translation_attributes: { title: 'Stored title', kb_locale: primary_locale })
  end

  let(:query) do
    <<~QUERY
      mutation knowledgeBaseAnswerVisibilityScheduleAdd($answerId: ID!, $visibility: EnumKnowledgeBaseSchedulableVisibility!, $scheduledAt: ISO8601DateTime!) {
        knowledgeBaseAnswerVisibilityScheduleAdd(answerId: $answerId, visibility: $visibility, scheduledAt: $scheduledAt) {
          answer {
            id
            title
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

  let(:scheduled_at) { 1.week.from_now.change(sec: 0) }
  let(:visibility)   { 'published' }
  let(:variables)    { { answerId: gql.id(answer), visibility:, scheduledAt: scheduled_at.iso8601 } }

  before do
    answer

    setup if defined?(setup)
    gql.execute(query, variables:)
  end

  context 'with an editor', authenticated_as: :editor do
    it 'returns the answer with its schedule', :aggregate_failures do
      expect(gql.result.data.dig('answer', 'id')).to eq(gql.id(answer))
      expect(gql.result.data.dig('answer', 'visibilitySchedules').sole)
        .to include('visibility' => 'published')
    end

    it 'schedules the change for the given date' do
      returned = gql.result.data.dig('answer', 'visibilitySchedules').sole['scheduledAt']

      expect(Time.zone.parse(returned)).to eq(scheduled_at)
    end

    # Nothing about the answer changes until the date is reached, so the state it renders back is
    #   still the one it is in.
    it 'leaves the rendered state alone' do
      expect(gql.result.data.dig('answer', 'visibility')).to eq('draft')
    end

    # A publication state belongs to the answer, so no locale is asked of the caller - but the answer
    #   it renders back has locale-dependent fields all the same, and those go straight into the
    #   client cache. They are localized like every knowledge base read without an explicit locale:
    #   in the current user's preferred locale, which here is the only one there is.
    it 'renders the answer in the preferred locale' do
      expect(gql.result.data.dig('answer', 'title')).to eq('Stored title')
    end

    # Whatever the service refuses has to reach the client as a user error rather than as a failed
    #   mutation - and named after the argument that has to change, which is what the flyout calls
    #   its fields. Otherwise the message lands at the top of the form instead of on the date.
    context 'when the service refuses the schedule' do
      let(:scheduled_at) { 1.week.ago }

      it 'returns a user error naming the date' do
        expect(gql.result.data['errors'])
          .to include(include('message' => 'A visibility change can only be scheduled for a point in time in the future.', 'field' => 'scheduledAt'))
      end
    end

    # This one is about the state, and no date makes it schedulable again.
    context 'when the state has already been reached' do
      let(:answer) do
        create(:knowledge_base_answer, :published, category:, translation_attributes: { kb_locale: primary_locale })
      end
      let(:visibility) { 'published' }

      it 'returns a user error naming the state' do
        expect(gql.result.data['errors'])
          .to include(include('field' => 'visibility'))
      end
    end

    # CanBePublished would refuse this too, but its error reports on the date it compares *from* -
    #   `archived_at` here, the pending archival the editor did not touch. The service says it about
    #   the submitted date instead, which is the one they can correct.
    context 'when the schedule could never take effect' do
      let(:answer) do
        create(:knowledge_base_answer, category:, archived_at: 1.week.from_now.change(sec: 0),
                                       translation_attributes: { kb_locale: primary_locale })
      end
      let(:scheduled_at) { 1.month.from_now.change(sec: 0) }

      it 'returns a user error naming the submitted date, not the pending archival', :aggregate_failures do
        expect(gql.result.data['errors'])
          .to include(include('message' => include('in the order internal, published, archived'), 'field' => 'scheduledAt'))
        expect(gql.result.data['errors'].pluck('field')).not_to include('archived_at')
      end
    end

    # `draft` stores no date, so it is not among the states a change can be scheduled to reach.
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
      it 'schedules the change' do
        expect(gql.result.data.dig('answer', 'visibilitySchedules')).to be_present
      end
    end

    # Gated on the way in, by the argument that loads the answer.
    context 'when the answer is in a category they only read', authenticated_as: :granular_editor do
      let(:answer) { create(:knowledge_base_answer, category: other_category) }

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
