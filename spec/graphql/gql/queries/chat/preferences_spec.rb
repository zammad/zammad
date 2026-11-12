# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Chat::Preferences, type: :graphql do
  let(:query) do
    <<~GQL
      query chatPreferences {
        chatPreferences {
          maxWindows
          alternativeName
          avatarEnabled
          topics {
            topic {
              id
              name
            }
            active
            phrases
          }
        }
      }
    GQL
  end

  let(:chat_enabled) { true }
  let(:preferences)  { {} }
  let(:agent)        { create(:agent, preferences:) }
  let(:support)      { create(:chat, name: 'Support') }
  let(:sales)        { create(:chat, name: 'Sales') }

  before do
    Setting.set('chat', chat_enabled)
    support
    sales
    create(:chat, name: 'Retired', active: false)
    Chat.where.not(id: [support.id, sales.id]).update_all(active: false)
    gql.execute(query)
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'has the defaults and every active topic while the agent never chose anything', :aggregate_failures do
      expect(gql.result.data).to eq(
        'maxWindows'      => 4,
        'alternativeName' => nil,
        'avatarEnabled'   => true,
        'topics'          => [
          { 'topic' => { 'id' => gql.id(sales), 'name' => 'Sales' }, 'active' => false, 'phrases' => [] },
          { 'topic' => { 'id' => gql.id(support), 'name' => 'Support' }, 'active' => false, 'phrases' => [] },
        ],
      )
    end

    # What the old interface stores: string keys, the limit as text.
    context 'with the preferences of the old interface' do
      let(:preferences) do
        {
          chat: {
            'max_windows'      => '6',
            'alternative_name' => 'Erika',
            'avatar_state'     => 'disabled',
            'active'           => { support.id.to_s => 'on' },
            'phrase'           => { support.id.to_s => 'Hello, I am Erika; Good day ;', sales.id.to_s => '' },
          },
        }
      end

      it 'reads them typed', :aggregate_failures do
        expect(gql.result.data).to eq(
          'maxWindows'      => 6,
          'alternativeName' => 'Erika',
          'avatarEnabled'   => false,
          'topics'          => [
            { 'topic' => { 'id' => gql.id(sales), 'name' => 'Sales' }, 'active' => false, 'phrases' => [] },
            { 'topic' => { 'id' => gql.id(support), 'name' => 'Support' }, 'active' => true, 'phrases' => ['Hello, I am Erika', 'Good day'] },
          ],
        )
      end
    end

    context 'with the topic ids stored as numbers' do
      let(:preferences) { { chat: { active: { support.id => 'on' } } } }

      it 'reads them as well' do
        expect(gql.result.data['topics']).to include(include('topic' => include('name' => 'Support'), 'active' => true))
      end
    end

    context 'when asked whether the agent may create a ticket' do
      let(:query) { 'query chatPreferences { chatPreferences { hasTicketCreateAccess } }' }
      let(:group) { create(:group) }

      context 'with a group the agent may create tickets in' do
        let(:agent) { create(:agent, groups: [group]) }

        it 'answers yes' do
          expect(gql.result.data['hasTicketCreateAccess']).to be(true)
        end
      end

      context 'with groups the agent may only read' do
        let(:agent) { create(:agent).tap { |user| user.group_names_access_map = { group.name => 'read' } } }

        it 'answers no' do
          expect(gql.result.data['hasTicketCreateAccess']).to be(false)
        end
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
