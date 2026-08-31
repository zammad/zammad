# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::KnowledgeBase::AnswerScreenBehavior, type: :graphql do
  let(:user) { create(:user, roles: [create(:role, permission_names: 'knowledge_base.editor')]) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentKnowledgeBaseAnswerScreenBehavior($screen: EnumKnowledgeBaseAnswerScreen!, $behavior: EnumKnowledgeBaseAnswerScreenBehavior!) {
        userCurrentKnowledgeBaseAnswerScreenBehavior(screen: $screen, behavior: $behavior) {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:screen)    { 'edit' }
  let(:variables) { { screen: screen, behavior: 'closeTabAndOpenCategory' } }

  def execute_graphql_query
    gql.execute(mutation, variables: variables)
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end

  context 'when the user is no knowledge base editor', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'returns an error' do
      expect(execute_graphql_query.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when user is authenticated', authenticated_as: :user do
    it 'stores the behavior', :aggregate_failures do
      expect(execute_graphql_query.data).to include('success' => true)
      expect(user.reload.preferences['knowledgeBaseAnswerSecondaryAction']).to eq('closeTabAndOpenCategory')
    end

    # A key per screen: somebody adding answers in a row wants to be left on the form, which is not
    #   what the same person wants after correcting one.
    context 'when it is the create screen' do
      let(:screen) { 'create' }

      it 'stores the behavior under its own key', :aggregate_failures do
        user.preferences['knowledgeBaseAnswerSecondaryAction'] = 'stayOnTab'
        user.save!

        expect(execute_graphql_query.data).to include('success' => true)

        expect(user.reload.preferences).to include(
          'knowledgeBaseAnswerCreateSecondaryAction' => 'closeTabAndOpenCategory',
          'knowledgeBaseAnswerSecondaryAction'       => 'stayOnTab',
        )
      end
    end

    context 'with an unknown screen' do
      let(:screen) { 'read' }

      it 'returns an error' do
        expect(execute_graphql_query.error_message)
          .to eq('Variable $screen of type EnumKnowledgeBaseAnswerScreen! was provided invalid value')
      end
    end

    # The whole reason this has a key of its own: the two views are configured independently, and
    #   writing the ticket key here would silently change the ticket detail view for the same user.
    it 'leaves the ticket screen behavior alone' do
      user.preferences['secondaryAction'] = 'closeTab'
      user.save!

      execute_graphql_query

      expect(user.reload.preferences).to include(
        'secondaryAction'                    => 'closeTab',
        'knowledgeBaseAnswerSecondaryAction' => 'closeTabAndOpenCategory',
      )
    end

    # Ticket-only options must not be reachable here - the enum, not a runtime check, is what
    #   rejects them.
    context 'with a ticket-only behavior' do
      let(:variables) { { screen: screen, behavior: 'closeTabOnTicketClose' } }

      it 'returns an error' do
        expect(execute_graphql_query.error_message)
          .to eq('Variable $behavior of type EnumKnowledgeBaseAnswerScreenBehavior! was provided invalid value')
      end
    end
  end
end
