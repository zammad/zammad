# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::ExternalReferences::IssueTrackerItemAdd, type: :graphql do
  let(:variables)          { { ticketId: gql.id(ticket), issueTrackerType: issue_tracker_type, issueTrackerLink: issue_tracker_link } }
  let(:ticket)             { create(:ticket) }
  let(:issue_tracker_type) { 'github' }
  let(:issue_tracker_link) { 'https://github.com/zammad/zammad/issues/1' }
  let(:other_link)         { 'https://github.com/another/link/issues/123' }
  let(:issue_item) do
    {
      id:         1,
      title:      'GitHub integration',
      url:        'https://github.com/zammad/zammad/issues/1',
      icon_state: 'closed',
      milestone:  '4.0',
      assignees:  ['Thorsten'],
      labels:     [
        {
          color:      '#84b6eb',
          text_color: '#000000',
          title:      'enhancement'
        },
        {
          color:      '#bfdadc',
          text_color: '#000000',
          title:      'integration'
        }
      ],
    }
  end

  let(:mutation) do
    <<~MUTATION
      mutation ticketExternalReferencesIssueTrackerItemAdd(
        $ticketId: ID
        $issueTrackerLink: UriHttpString!
        $issueTrackerType: EnumTicketExternalReferencesIssueTrackerType!
      ) {
        ticketExternalReferencesIssueTrackerItemAdd(
          ticketId: $ticketId
          issueTrackerLink: $issueTrackerLink
          issueTrackerType: $issueTrackerType
        ) {
          issueTrackerItem {
            issueId
            title
            url
          }
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  before do
    Setting.set('github_integration', true)
    Setting.set('github_config', { 'endpoint' => 'https://api.github.com/graphql', 'api_token' => 'example' })
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    context 'when ticket is used' do
      let(:variables) { { ticketId: gql.id(ticket), issueTrackerType: issue_tracker_type, issueTrackerLink: issue_tracker_link } }
      let(:ticket)    { create(:ticket) }

      context 'when an agent has access to the ticket' do
        before do
          agent.groups << ticket.group
        end

        context 'when the link already exists' do
          before do
            ticket.preferences[:github] = { issue_links: [other_link, issue_tracker_link] }
            ticket.save!
          end

          it 'returns a user error' do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:errors].first).to include('field' => 'link', 'message' => 'The issue reference already exists.')
          end
        end

        context 'when new link should be added' do
          before do
            allow_any_instance_of(Service::Ticket::ExternalReferences::IssueTracker::Item)
              .to receive(:execute)
              .and_return(issue_item)

            allow(Service::Ticket::ExternalReferences::IssueTracker::Item).to receive(:new).and_call_original
          end

          it 'returns issue item', aggregate_failures: true do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:issueTrackerItem]).to eq(
              {
                'issueId' => issue_item[:id],
                'title'   => issue_item[:title],
                'url'     => issue_item[:url]
              }
            )

            expect(ticket.reload.preferences)
              .to include(github: include(issue_links: contain_exactly(issue_tracker_link)))
          end
        end

        context 'when wrong link is used' do
          let(:issue_tracker_link) { 'https://github.com/zammad/zammad/wrong/1' }

          it 'returns a user error' do
            gql.execute(mutation, variables: variables)

            expect(gql.result.data[:errors].first).to include('field' => 'link', 'message' => 'Invalid GitHub issue link format')
          end
        end
      end

      context 'when an agent has no access to the ticket' do
        before { gql.execute(mutation, variables:) }

        it_behaves_like 'graphql responds with error if unauthenticated'
      end
    end

    context 'without a ticket' do
      let(:variables) { { issueTrackerType: issue_tracker_type, issueTrackerLink: issue_tracker_link } }

      context 'when new link should be added' do
        before do
          allow_any_instance_of(Service::Ticket::ExternalReferences::IssueTracker::Item)
            .to receive(:execute)
            .and_return(issue_item)

          allow(Service::Ticket::ExternalReferences::IssueTracker::Item).to receive(:new).and_call_original
        end

        it 'returns issue item', aggregate_failures: true do
          gql.execute(mutation, variables: variables)

          expect(gql.result.data[:issueTrackerItem]).to eq(
            {
              'issueId' => issue_item[:id],
              'title'   => issue_item[:title],
              'url'     => issue_item[:url]
            }
          )
        end
      end

    end
  end

  context 'when unauthenticated' do
    before { gql.execute(mutation, variables:) }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
