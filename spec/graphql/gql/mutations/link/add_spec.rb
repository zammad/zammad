# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Link::Add, :aggregate_failures, type: :graphql do
  let(:mutation) do
    <<~MUTATION
      mutation linkAdd($input: LinkInput!) {
        linkAdd(input: $input) {
          link {
            type
            item {
              ... on Ticket {
                id
                title
              }
            }
          }
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  let(:from_group) { create(:group) }
  let(:from)       { create(:ticket, group: from_group) }
  let(:to_group)   { create(:group) }
  let(:to)         { create(:ticket, group: to_group) }
  let(:type)       { ENV.fetch('LINK_TYPE') { %w[child parent normal].sample } }

  let(:input) do
    {
      sourceId: gql.id(to),
      targetId: gql.id(from),
      type:     type
    }
  end

  let(:variables) { { input: input } }

  before do
    next if RSpec.configuration.formatters.first
      .class.name.exclude?('DocumentationFormatter')

    puts "with link type: #{type}" # rubocop:disable Rails/Output
  end

  context 'with unauthenticated session' do
    it 'raises an error' do
      gql.execute(mutation, variables: variables)
      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  context 'with authenticated session', authenticated_as: :authenticated do
    let(:authenticated) { create(:agent, groups: [from_group, to_group]) }

    it 'adds link' do
      expect { gql.execute(mutation, variables: variables) }
        .to change(Link, :count).by(1)
      expect(gql.result.data[:link]).to eq(
        {
          'type' => type,
          'item' => { 'id' => gql.id(to), 'title' => to.title }
        }
      )
    end

    context 'when link already exists' do
      before { create(:link, from: to, to: from, link_type: type) }

      it 'returns error' do
        expect { gql.execute(mutation, variables: variables) }
          .not_to change(Link, :count)
        expect(gql.result.data[:link]).to be_nil
        expect(gql.result.data[:errors]).to contain_exactly(
          hash_including('message' => 'Link already exists', 'field' => nil)
        )
      end
    end

    context 'when source is not accessible' do
      let(:authenticated) { create(:agent, groups: [to_group]) }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when target is not accessible' do
      let(:authenticated) { create(:agent, groups: [from_group]) }

      it 'raises an error' do
        gql.execute(mutation, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
