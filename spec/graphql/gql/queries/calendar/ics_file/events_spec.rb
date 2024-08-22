# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Calendar::IcsFile::Events, authenticated_as: :user, type: :graphql do
  let(:query) do
    <<~QUERY
      query calendarIcsFileEvents($fileId: ID!) {
        calendarIcsFileEvents(fileId: $fileId) {
          title
          location
          startDate
          endDate
          organizer
          attendees
          description
        }
      }
    QUERY
  end

  let(:ticket)        { create(:ticket) }
  let(:calendar_file) { create(:store, :ics, object: 'Ticket', o_id: ticket.id) }

  let(:variables) { { fileId: gql.id(calendar_file) } }

  before do
    gql.execute(query, variables: variables)
  end

  context 'when an agent is fetching events from an ICS file' do
    let(:user) { create(:agent, groups: [ticket.group]) }

    it 'returns the events' do
      expect(gql.result.data).to eq(
        [{
          'title'       => 'Test Summary',
          'location'    => 'https://us.zoom.us/j/example?pwd=test',
          'startDate'   => '2021-07-27T10:30:00+02:00',
          'endDate'     => '2021-07-27T12:00:00+02:00',
          'attendees'   => ['M.bob@example.com', 'J.doe@example.com'],
          'organizer'   => 'f.sample@example.com',
          'description' => 'Test description'
        }],
      )
    end

    context 'when the agent has no permission to access the ticket' do
      let(:user) { create(:agent, groups: []) }

      it 'returns an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'when not authenticated' do
    let(:user) { nil }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
