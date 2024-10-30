# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::ExternalReferences::IssueTrackerItemRemove, type: :graphql do
  let(:variables)          { { ticketId: gql.id(ticket), issueTrackerType: issue_tracker_type, issueTrackerLink: issue_tracker_link } }
  let(:issue_tracker_type) { 'github' }
  let(:issue_tracker_link) { 'https://github.com/zammad/zammad/issues/1' }
  let(:ticket)             { create(:ticket) }
  let(:other_link)         { 'https://github.com/another/link/issues/123' }

  let(:mutation) do
    <<~MUTATION
      mutation ticketExternalReferencesIssueTrackerItemRemove(
        $ticketId: ID!
        $issueTrackerLink: UriHttpString!
        $issueTrackerType: EnumTicketExternalReferencesIssueTrackerType!
      ) {
        ticketExternalReferencesIssueTrackerItemRemove(
          ticketId: $ticketId
          issueTrackerLink: $issueTrackerLink
          issueTrackerType: $issueTrackerType
        ) {
          success
          errors {
            message
          }
        }
      }
    MUTATION
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    context 'when an agent has access to the ticket' do
      before { agent.groups << ticket.group }

      context 'when the link exists' do
        before do
          ticket.preferences[:github] = { issue_links: [other_link, issue_tracker_link] }
          ticket.save!
        end

        it 'removes the link' do
          gql.execute(mutation, variables:)

          expect(ticket.reload.preferences)
            .to include(github: include(issue_links: contain_exactly(other_link)))
        end
      end

      context 'when the link is missing' do
        it 'returns success anyway' do
          gql.execute(mutation, variables:)

          expect(gql.result.data).to include({ 'success' => true })
        end
      end
    end

    context 'when an agent has no access to the ticket' do
      before { gql.execute(mutation, variables:) }

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end

  context 'when unauthenticated' do
    before { gql.execute(mutation, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
