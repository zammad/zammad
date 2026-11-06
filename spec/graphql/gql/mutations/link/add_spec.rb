# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What linking does is covered by spec/services/service/link/add_spec.rb — this covers the GraphQL surface only:
#   authorization, how the service's refusals reach the client, and the payload.
RSpec.describe Gql::Mutations::Link::Add, :aggregate_failures, type: :graphql do
  %w[child parent normal].each do |link_type|
    context "with link type #{link_type}" do
      let(:type) { link_type }

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

      let(:input) do
        {
          sourceId: gql.id(to),
          targetId: gql.id(from),
          type:     type
        }
      end

      let(:variables) { { input: input } }

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

        context 'when the two are linked the other way round already' do
          before { create(:link, from: from, to: to, link_type: 'normal') }

          it 'returns the error of the link service' do
            expect { gql.execute(mutation, variables: variables) }
              .not_to change(Link, :count)
            expect(gql.result.data[:errors]).to contain_exactly(
              hash_including('message' => 'Link already exists', 'field' => nil)
            )
          end
        end

        context 'when source is the target' do
          let(:input) do
            {
              sourceId: gql.id(from),
              targetId: gql.id(from),
              type:     type
            }
          end

          it 'returns error' do
            expect { gql.execute(mutation, variables: variables) }
              .not_to change(Link, :count)
            expect(gql.result.data[:link]).to be_nil
            expect(gql.result.data[:errors]).to contain_exactly(
              hash_including('message' => 'An object cannot be linked to itself.', 'field' => nil)
            )
          end
        end

        context 'when source is not accessible' do
          let(:authenticated) { create(:agent, groups: [to_group]) }

          it 'raises an error' do
            gql.execute(mutation, variables: variables)
            expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
          end
        end

        context 'when target is not accessible' do
          let(:authenticated) { create(:agent, groups: [from_group]) }

          it 'raises an error' do
            gql.execute(mutation, variables: variables)
            expect(gql.result.error_type).to eq(Pundit::NotAuthorizedError)
          end
        end
      end
    end
  end
end
