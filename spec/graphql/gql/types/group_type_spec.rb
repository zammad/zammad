# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Types::GroupType do
  let(:instance) { described_class.send(:new, group, nil) }

  context 'when group has an email' do
    let(:group) { create(:group) }

    it 'has email address and name' do
      expect(instance.email_address)
        .to include(name: group.email_address.realname, email_address: group.email_address.email)
    end
  end

  context 'when group has no email' do
    let(:group) { create(:group, email_address: nil) }

    it 'has no email address' do
      expect(instance.email_address).to be_nil
    end
  end

  context 'when testing query', authenticated_as: :agent, type: :graphql do
    let(:agent)     { create(:agent, groups: [group]) }
    let(:ticket)    { create(:ticket, group: group) }
    let(:variables) { { ticketId: gql.id(ticket) } }
    let(:query) do
      <<~QUERY
        query ticket($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String) {
          ticket(
            ticket: {
              ticketId: $ticketId
              ticketInternalId: $ticketInternalId
              ticketNumber: $ticketNumber
            }
          ) {
            id
            group {
              name
              emailAddress {
                name
                emailAddress
              }
            }
          }
        }
      QUERY
    end

    before do
      ticket
      gql.execute(query, variables: variables)
    end

    context 'when group has an email' do
      let(:group) { create(:group) }
      let(:expected_result) do
        {
          'id'    => gql.id(ticket),
          'group' => include(
            'name'         => group.name,
            'emailAddress' => include(
              'name'         => group.email_address.realname,
              'emailAddress' => group.email_address.email,
            )
          ),
        }
      end

      it 'has email address and name' do
        expect(gql.result.data).to include(expected_result)
      end
    end

    context 'when group has no email' do
      let(:group) { create(:group, email_address: nil) }
      let(:expected_result) do
        {
          'id'    => gql.id(ticket),
          'group' => include(
            'name'         => group.name,
            'emailAddress' => nil
          ),
        }
      end

      it 'has no email address' do
        expect(gql.result.data).to include(expected_result)
      end
    end
  end
end
