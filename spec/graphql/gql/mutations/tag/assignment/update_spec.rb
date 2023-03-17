# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Tag::Assignment::Update, :aggregate_failures, type: :graphql do
  context 'when updating tags', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [object.group]) }
    let(:query) do
      <<~QUERY
        mutation tagAssignmentUpdate($tags: [String!]!, $objectId: ID!) {
          tagAssignmentUpdate(tags: $tags, objectId: $objectId) {
            success
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    let(:variables) do
      {
        tags:     tags_list,
        objectId: gql.id(object),
      }
    end

    let(:object) { create(:ticket) }
    let(:tags_list) { %w[tag1 other_tag] }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with ticket write permission' do
      it 'adds the tag' do
        expect(gql.result.data['success']).to be(true)
        expect(object.reload.tag_list).to match_array(tags_list)
      end

      it 'removes the tag' do
        (tags_list + ['tag3']).each { |elem| object.tag_add elem }
        gql.execute(query, variables: variables)

        expect(gql.result.data['success']).to be(true)
        expect(object.reload.tag_list).to eq(tags_list)
      end
    end

    context 'with ticket read permission' do
      let(:agent) { create(:agent, groups: [object.group], group_names_access_map: { object.group.name => 'read' }) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without permission' do
      let(:agent) { create(:agent) }

      it 'raises an error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
