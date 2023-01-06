# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::Signature, type: :graphql do
  let(:signature) { create(:signature, body: "\#{user.fullname} via \#{config.product_name}") }
  let(:group)     { create(:group, signature_id: signature.id) }
  let(:query)     do
    <<~QUERY
      query ticketSignature($groupId: ID!, $ticketId: ID) {
        ticketSignature(groupId: $groupId) {
          id
          renderedBody(ticketId: $ticketId)
        }
      }
    QUERY
  end
  let(:variables) { { groupId: gql.id(group) } }

  before do
    gql.execute(query, variables: variables)
  end

  context 'with an agent', authenticated_as: :user do
    context 'with permission' do
      let(:user) { create(:agent, groups: [group]) }

      context 'without ticket context' do
        it 'returns data' do
          expect(gql.result.data).to eq({
                                          'id'           => gql.id(signature),
                                          'renderedBody' => "#{user.fullname} via #{Setting.get('product_name')}",
                                        })
        end
      end

      context 'with ticket context' do
        let(:signature) { create(:signature, body: "\#{user.fullname} via \#{config.product_name} (\#{ticket.number})") }
        let(:ticket)    { create(:ticket, group: group) }
        let(:variables) { { groupId: gql.id(group), ticketId: gql.id(ticket) } }

        it 'returns data' do
          expect(gql.result.data).to eq({
                                          'id'           => gql.id(signature),
                                          'renderedBody' => "#{user.fullname} via #{Setting.get('product_name')} (#{ticket.number})",
                                        })
        end
      end

      context 'without assigned signature to the group' do
        let(:group) { create(:group) }

        it 'returns no data' do
          expect(gql.result.data).to be_nil
        end
      end

      context 'with inactive signature' do
        let(:signature) { create(:signature, active: false) }

        it 'returns no data' do
          expect(gql.result.data).to be_nil
        end
      end

      context 'with empty body signature' do
        let(:signature) { create(:signature, body: '') }

        it 'returns no data' do
          expect(gql.result.data).to be_nil
        end
      end
    end

    context 'without permission' do
      let(:user) { create(:agent) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'with a customer', authenticated_as: :user do
    let(:user) { create(:customer) }

    it 'raises an error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
