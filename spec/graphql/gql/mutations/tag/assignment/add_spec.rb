# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

    context 'with ticket write permission' do
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

    context 'when assigning a new tag to KB answer', authenticated_as: :user do
      include_context 'basic Knowledge Base'

      let(:object) { published_answer }

      context 'when user is editor' do
        let(:user)   { create(:admin) }

        it 'adds the tag' do
          expect(gql.result.data['success']).to be(true)
          expect(object.reload.tag_list).to eq([tag])
        end
      end

      context 'when user is not editor' do
        let(:user) { create(:agent) }

        it 'raises an error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end
    end
  end
end
