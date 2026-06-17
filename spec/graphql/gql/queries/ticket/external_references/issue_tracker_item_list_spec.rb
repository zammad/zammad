# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::ExternalReferences::IssueTrackerItemList, type: :graphql do
  let(:variables)           { { issueTrackerType: issue_tracker_type, ticketId: gql.id(ticket) } }
  let(:ticket)              { create(:ticket) }
  let(:issue_tracker_type)  { 'github' }

  let(:query) do
    <<~QUERY
      query ticketExternalReferencesIssueTrackerItemList(
        $issueTrackerLinks: [UriHttpString!]
        $ticketId: ID
        $issueTrackerType: EnumTicketExternalReferencesIssueTrackerType!
      ) {
        ticketExternalReferencesIssueTrackerItemList(
          issueTrackerType: $issueTrackerType
          input: {
            issueTrackerLinks: $issueTrackerLinks
            ticketId: $ticketId
          }
        ) {
          assignees
          issueId
          issueType {
            color
            name
          }
          labels {
            color
            textColor
            title
          }
          milestone
          state
          title
          url
        }
      }
    QUERY
  end

  let(:issue_list) do
    [
      {
        id:         1,
        title:      'GitHub integration',
        url:        'https://github.com/zammad/zammad/issues/1',
        icon_state: 'closed',
        issue_type: { name: 'Story', color: 'PURPLE' },
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
    ]
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [ticket.group]) }

    context 'with a GitHub issue tracker' do
      context 'when ticket is used' do
        before do
          allow(Service::Ticket::ExternalReferences::IssueTracker::TicketList)
            .to receive(:execute)
            .and_return(issue_list)

          gql.execute(query, variables: variables)
        end

        it 'returns issue list', aggregate_failures: true do
          expect(gql.result.data).to eq(issue_list.map do |item|
            item.merge(
              issueId:   item[:id],
              state:     item[:icon_state],
              issueType: item[:issue_type] && {
                name:  item[:issue_type][:name],
                color: item[:issue_type][:color],
              },
              labels:    item[:labels].map do |label|
                {
                  title:     label[:title],
                  textColor: label[:text_color],
                  color:     label[:color]
                }
              end
            ).except(:id, :icon_state, :issue_type).deep_stringify_keys
          end)

          expect(Service::Ticket::ExternalReferences::IssueTracker::TicketList)
            .to have_received(:execute).with(type: 'github', ticket: ticket)
        end
      end

      context 'with temporary issue tracker links' do
        let(:issue_tracker_links) { ['https://github.com/zammad/zammad/issues/1'] }
        let(:variables)           { { issueTrackerType: issue_tracker_type, issueTrackerLinks: issue_tracker_links } }

        before do
          allow(Service::Ticket::ExternalReferences::IssueTracker::FetchMetadata)
            .to receive(:execute)
            .and_return(issue_list)

          gql.execute(query, variables: variables)
        end

        it 'returns issue list', aggregate_failures: true do
          expect(gql.result.data).to eq(issue_list.map do |item|
            item.merge(
              issueId:   item[:id],
              state:     item[:icon_state],
              issueType: item[:issue_type] && {
                name:  item[:issue_type][:name],
                color: item[:issue_type][:color],
              },
              labels:    item[:labels].map do |label|
                {
                  title:     label[:title],
                  textColor: label[:text_color],
                  color:     label[:color]
                }
              end
            ).except(:id, :icon_state, :issue_type).deep_stringify_keys
          end)

          expect(Service::Ticket::ExternalReferences::IssueTracker::FetchMetadata)
            .to have_received(:execute).with(type: 'github', issue_links: issue_tracker_links)
        end
      end

      context 'when issue has no type (personal repo or untyped issue)' do
        let(:issue_list_no_type) do
          [issue_list.first.merge(issue_type: nil)]
        end

        before do
          allow(Service::Ticket::ExternalReferences::IssueTracker::TicketList)
            .to receive(:execute)
            .and_return(issue_list_no_type)

          gql.execute(query, variables: variables)
        end

        it 'returns issueType as null' do
          expect(gql.result.data.first['issueType']).to be_nil
        end
      end
    end

    context 'with missing arguments' do
      let(:variables) { { issueTrackerType: issue_tracker_type } }

      before do
        gql.execute(query, variables: variables)
      end

      it 'raises an exception' do
        expect(gql.result.error_type).to eq(GraphQL::Schema::Validator::ValidationFailedError)
      end
    end
  end

  context 'when unauthenticated' do
    before do
      gql.execute(query, variables: variables)
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
