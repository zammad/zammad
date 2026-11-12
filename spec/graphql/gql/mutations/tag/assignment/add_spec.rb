# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Tag::Assignment::Add, :aggregate_failures, type: :graphql do
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

  context 'when assigning a new tag', authenticated_as: :agent do
    let(:tag)          { 'tag1' }
    let(:chat_enabled) { true }

    before do
      Setting.set('chat', chat_enabled)
      gql.execute(query, variables: variables)
    end

    context 'with ticket write permission' do
      it 'adds the tag' do
        expect(gql.result.data[:success]).to be(true)
        expect(object.reload.tag_list).to eq([tag])
      end

      it 'adds an already assigned tag' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:success]).to be(true)
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
          expect(gql.result.data[:success]).to be(true)
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

    context 'when assigning a new tag to a chat session', authenticated_as: :user do
      let(:session_owner) { create(:agent) }
      let(:object)        { create(:'chat/session', chat: create(:chat), state: 'closed', user: session_owner) }

      context 'when the user ran the session' do
        let(:user) { session_owner }

        it 'adds the tag' do
          expect(gql.result.data[:success]).to be(true)
          expect(object.reload.tag_list).to eq([tag])
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

  context 'when tag creation is disabled', authenticated_as: :agent do
    let(:tag) { SecureRandom.hex(4) }

    before do
      Setting.set('tag_new', false)
      gql.execute(query, variables: variables)
    end

    it 'does not add the tag' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
