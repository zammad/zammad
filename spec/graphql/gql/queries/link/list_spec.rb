# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Link::List, type: :graphql do
  context 'when fetching link list' do
    let(:from_group)    { create(:group) }
    let(:from)          { create(:ticket, group: from_group) }
    let(:to_group)      { create(:group) }
    let(:to)            { create(:ticket, group: to_group) }
    let(:link)          { create(:link, from:, to:) }

    let(:variables) { { objectId: gql.id(from), targetType: 'Ticket' } }

    let(:query) do
      <<~QUERY
        query linkList($objectId: ID!, $targetType: String!) {
          linkList(objectId: $objectId, targetType: $targetType) {
            type
            source {
              ... on Ticket {
                id
                title
              }
            }
            target {
              ... on Ticket {
                id
                title
              }
            }
          }
        }
      QUERY
    end

    before do
      link
      gql.execute(query, variables: variables)
    end

    context 'with authenticated session', authenticated_as: :authenticated do
      let(:authenticated) { create(:agent, groups: [from_group, to_group]) }

      it 'returns link list' do
        expect(gql.result.data.first).to eq(
          {
            'source' => { 'id' => gql.id(from), 'title' => from.title },
            'target' => { 'id' => gql.id(to), 'title' => to.title },
            'type'   => 'normal'
          }
        )
      end

      context 'when source is not accessible' do
        let(:authenticated) { create(:agent, groups: [to_group]) }

        it 'raises an error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'when target is not accessible' do
        before do
          create(:link, from: from, to: create(:ticket))
        end

        it 'returns link list without the related link', :aggregate_failures do
          expect(Link.count).to eq(2)
          expect(gql.result.data.size).to eq(1)
        end
      end
    end
  end
end
