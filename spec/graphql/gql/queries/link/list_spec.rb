# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Link::List, type: :graphql do
  context 'when fetching link list' do
    let(:from_group)    { create(:group) }
    let(:from)          { create(:ticket, group: from_group) }
    let(:to_group)      { create(:group) }
    let(:to)            { create(:ticket, group: to_group) }
    let(:type)          { ENV.fetch('LINK_TYPE') { %w[child parent normal].sample } }
    let(:link)          { create(:link, from:, to:, link_type: type) }

    let(:variables) { { objectId: gql.id(from), targetType: 'Ticket' } }

    let(:query) do
      <<~QUERY
        query linkList($objectId: ID!, $targetType: String!) {
          linkList(objectId: $objectId, targetType: $targetType) {
            type
            item {
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

      next if RSpec.configuration.formatters.first
        .class.name.exclude?('DocumentationFormatter')

      puts "with link type: #{type}" # rubocop:disable Rails/Output
    end

    context 'with authenticated session', authenticated_as: :authenticated do
      let(:authenticated) { create(:agent, groups: [from_group, to_group]) }

      it 'returns link list' do
        link_type = if type == 'normal'
                      type
                    else
                      type == 'parent' ? 'child' : 'parent'
                    end

        expect(gql.result.data.first).to eq(
          {
            'item' => { 'id' => gql.id(to), 'title' => to.title },
            'type' => link_type
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
          create(:link, from: from, to: create(:ticket), link_type: type)
        end

        it 'returns link list without the related link', :aggregate_failures do
          expect(Link.count).to eq(2)
          expect(gql.result.data.size).to eq(1)
        end
      end
    end
  end
end
