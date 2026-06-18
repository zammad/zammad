require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::ParticipantRemove, :aggregate_failures, type: :graphql, current_user_id: 1 do
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:customer) { create(:customer) }
  let(:ticket)   { create(:ticket, group: group) }

  let(:query) do
    <<~QUERY
      mutation ticketParticipantRemove($ticketId: ID!, $userId: ID!) {
        ticketParticipantRemove(ticketId: $ticketId, userId: $userId) {
          success
          errors { message }
        }
      }
    QUERY
  end

  let(:variables) do
    { ticketId: gql.id(ticket), userId: gql.id(customer) }
  end

  before do
    Setting.set('ticket_participants_enabled', true)
    Mention.subscribe!(ticket, customer)
  end

  after do
    Setting.set('ticket_participants_enabled', false)
  end

  it 'is registered in schema (BaseMutation descendant)' do
    expect(described_class < Gql::Mutations::BaseMutation).to be true
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    it 'removes a participant via GraphQL' do
      gql.execute(query, variables: variables)
      data = gql.result.payload[:data]
      expect(data).to be_present
      expect(data[:ticketParticipantRemove][:success]).to be true
    end
  end
end
