# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Tag::Assignment::Add, :aggregate_failures, type: :graphql do
  context 'when assigning a new tag', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [object.group]) }
    let(:query) do
      <<~QUERY
        mutation tagAssignmentAdd($tag: String!, $objectId: ID!) {
          tagAssignmentAdd(tag: $tag, objectId: $objectId) {
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
        tag:      tag,
        objectId: gql.id(object),
      }
    end

    let(:object) { create(:ticket) }
    let(:tag) { 'tag1' }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with permission' do
      it 'adds the tag' do
        expect(gql.result.data['success']).to be(true)
        expect(object.reload.tag_list).to eq([tag])
      end

      it 'adds an already assigned tag' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['success']).to be(true)
        expect(object.reload.tag_list).to eq([tag])
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
