require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::ParticipantAdd, :aggregate_failures, type: :graphql do
  let(:group)    { create(:group) }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:customer) { create(:customer) }
  let(:ticket)   { create(:ticket, group: group) }

  let(:query) do
    <<~QUERY
      mutation ticketParticipantAdd($ticketId: ID!, $userId: ID!) {
        ticketParticipantAdd(ticketId: $ticketId, userId: $userId) {
          participant { id }
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
  end

  after do
    Setting.set('ticket_participants_enabled', false)
  end

  it 'is registered in schema (BaseMutation descendant)' do
    expect(described_class < Gql::Mutations::BaseMutation).to be true
  end

  context 'when logged in as an agent', authenticated_as: :agent do
    it 'adds a customer as participant via GraphQL' do
      gql.execute(query, variables: variables)
      data = gql.result.payload[:data]
      expect(data).to be_present
      expect(data[:ticketParticipantAdd][:participant]).to be_present
    end
  end

  context 'when the participant is already a participant', authenticated_as: :agent do
    before do
      UserInfo.current_user_id = agent.id
      Mention.subscribe!(ticket, customer)
    end

    it 'returns an error message' do
      gql.execute(query, variables: variables)
      data = gql.result.payload[:data]
      expect(data[:ticketParticipantAdd][:participant]).to be_nil
      expect(data[:ticketParticipantAdd][:errors]).to be_present
      expect(data[:ticketParticipantAdd][:errors].first[:message]).to include('already a participant')
    end
  end

  context 'when the user is the ticket customer', authenticated_as: :agent do
    let(:ticket) { create(:ticket, group: group, customer: customer) }

    it 'returns an error message' do
      gql.execute(query, variables: variables)
      data = gql.result.payload[:data]
      expect(data[:ticketParticipantAdd][:participant]).to be_nil
      expect(data[:ticketParticipantAdd][:errors]).to be_present
      expect(data[:ticketParticipantAdd][:errors].first[:message]).to include('ticket customer')
    end
  end

  context 'when the user is an agent', authenticated_as: :agent do
    let(:other_agent) { create(:agent, groups: [group]) }
    let(:variables)   { { ticketId: gql.id(ticket), userId: gql.id(other_agent) } }

    it 'returns an error message' do
      gql.execute(query, variables: variables)
      data = gql.result.payload[:data]
      expect(data[:ticketParticipantAdd][:participant]).to be_nil
      expect(data[:ticketParticipantAdd][:errors]).to be_present
      expect(data[:ticketParticipantAdd][:errors].first[:message]).to include('cannot be added')
    end
  end

  context 'when the participants are already at the cap', authenticated_as: :agent do
    let(:other_customer) { create(:customer) }
    let(:variables)      { { ticketId: gql.id(ticket), userId: gql.id(other_customer) } }

    before do
      UserInfo.current_user_id = agent.id
      # Put 50 participants on the ticket
      50.times do |i|
        user = create(:customer, email: "cap_test_#{i}@example.com")
        Mention.subscribe!(ticket, user)
      end
    end

    it 'returns a top-level GraphQL error' do
      gql.execute(query, variables: variables)
      expect(gql.result.payload[:errors]).to be_present
      expect(gql.result.payload[:errors].first[:message]).to include('Maximum of 50')
    end
  end

end
