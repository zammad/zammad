# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What is stored and refused is covered by spec/services/service/chat/preferences/update_spec.rb —
#   this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::Chat::Preferences::Update, type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation chatPreferencesUpdate($preferences: ChatPreferencesInput!) {
        chatPreferencesUpdate(preferences: $preferences) {
          preferences {
            maxWindows
            alternativeName
            avatarEnabled
            topics {
              topic {
                id
              }
              active
              phrases
            }
          }
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:chat_enabled) { true }
  let(:support)      { create(:chat, name: 'Support') }
  let(:agent)        { create(:agent) }
  let(:preferences) do
    {
      maxWindows:      6,
      alternativeName: 'Erika',
      avatarEnabled:   false,
      topics:          [{ topicId: gql.id(support), active: true, phrases: ['Hello, I am Erika'] }],
    }
  end
  let(:variables) { { preferences: } }

  before do
    Setting.set('chat', chat_enabled)
    Chat.where.not(id: support.id).update_all(active: false)
    gql.execute(mutation, variables:)
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'returns the stored preferences typed', :aggregate_failures do
      expect(gql.result.data['preferences']).to eq(
        'maxWindows'      => 6,
        'alternativeName' => 'Erika',
        'avatarEnabled'   => false,
        'topics'          => [{ 'topic' => { 'id' => gql.id(support) }, 'active' => true, 'phrases' => ['Hello, I am Erika'] }],
      )
      expect(Chat.agent_active_chat_ids(agent.reload)).to eq([support.id])
    end

    context 'with only some of the preferences' do
      let(:preferences) { { maxWindows: 9 } }

      it 'changes only those' do
        expect(gql.result.data['preferences']).to include('maxWindows' => 9, 'avatarEnabled' => true)
      end
    end

    context 'with a limit out of range' do
      let(:preferences) { { maxWindows: 21 } }

      it 'returns the user error', :aggregate_failures do
        expect(gql.result.data['preferences']).to be_nil
        expect(gql.result.data['errors']).to eq([{ 'message' => 'The number of concurrent chats must be between 1 and 20.', 'field' => nil }])
      end
    end

    context 'with an id that is no topic' do
      let(:preferences) { { topics: [{ topicId: gql.id(agent), active: true, phrases: [] }] } }

      it 'is not found' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the chat feature is switched off' do
      let(:chat_enabled) { false }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'with a user without the chat.agent permission', authenticated_as: :user do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
