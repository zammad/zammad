# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Tag::Assignment::Remove, :aggregate_failures, type: :graphql do
  context 'when removing a tag', authenticated_as: :agent do
    let(:agent) { create(:agent, groups: [object.group]) }
    let(:query) do
      <<~QUERY
        mutation tagAssignmentRemove($tag: String!, $objectId: ID!) {
          tagAssignmentRemove(tag: $tag, objectId: $objectId) {
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

    let(:object) { create(:ticket).tap { |t| t.tag_add(tag, 1) } }
    let(:tag) { 'tag1' }

    before do
      gql.execute(query, variables: variables)
    end

    context 'with ticket write permission' do
      it 'removes the tag' do
        expect(gql.result.data['success']).to be(true)
        expect(object.reload.tag_list).to eq([])
      end

      context 'when trying to remove a nonassigned tag' do
        let(:object) { create(:ticket) }

        it 'returns success nevertheless' do
          expect(gql.result.data['success']).to be(true)
        end
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
