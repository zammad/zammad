# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
    let(:tag)          { 'tag1' }
    let(:chat_enabled) { true }

    before do
      Setting.set('chat', chat_enabled)
      gql.execute(query, variables: variables)
    end

    context 'with ticket write permission' do
      it 'removes the tag' do
        expect(gql.result.data[:success]).to be(true)
        expect(object.reload.tag_list).to eq([])
      end

      context 'when trying to remove a nonassigned tag' do
        let(:object) { create(:ticket) }

        it 'returns success nevertheless' do
          expect(gql.result.data[:success]).to be(true)
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

    context 'when removing a tag from a chat session', authenticated_as: :user do
      let(:session_owner) { create(:agent) }
      let(:object) do
        create(:'chat/session', chat: create(:chat), state: 'closed', user: session_owner).tap { |s| s.tag_add(tag, 1) }
      end

      context 'when the user ran the session' do
        let(:user) { session_owner }

        it 'removes the tag' do
          expect(gql.result.data[:success]).to be(true)
          expect(object.reload.tag_list).to eq([])
        end
      end

      context 'when another agent ran the session' do
        let(:user) { create(:agent) }

        it 'raises an error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end

      context 'when chat is disabled' do
        let(:user)         { session_owner }
        let(:chat_enabled) { false }

        it 'raises an error' do
          expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        end
      end
    end
  end
end
