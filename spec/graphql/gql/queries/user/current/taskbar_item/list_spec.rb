# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::TaskbarItem::List, type: :graphql do
  context 'when listing user taskbar items' do
    let(:agent)     { create(:agent) }
    let(:variables) { {} }
    let(:query) do
      <<~QUERY
        query userCurrentTaskbarItemList($app: EnumTaskbarApp) {
          userCurrentTaskbarItemList(app: $app) {
            app
            key
            entity {
              ... on User {
                id
              }
            }
          }
        }
      QUERY
    end

    before do
      %w[desktop desktop mobile].each do |app|
        create(:taskbar, user_id: agent.id, app: app, key: "User-#{create(:customer).id}")
      end

      gql.execute(query, variables: variables)
    end

    context 'when user is not authenticated' do
      it 'returns an error' do
        expect(gql.result.error_message).to eq('Authentication required')
      end
    end

    context 'when user is authenticated', authenticated_as: :agent do
      context 'when no app is specified' do
        it 'returns all taskbar items' do
          expect(gql.result.data.size).to eq(3)
        end
      end

      context 'when app is specified', :aggregate_failures do
        let(:variables) { { app: 'desktop' } }

        it 'returns taskbar items for the specified app' do
          result = gql.result.data

          expect(result.size).to eq(2)
          expect(result.pluck('app')).to all(eq('desktop'))
        end
      end
    end
  end

  # A create screen has no record behind it, so its entity is resolved from the taskbar state
  #   instead of the database - which the union has to render as its own type.
  context 'when listing a knowledge base answer create item' do
    let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
    let(:editor)      { create(:user, roles: [editor_role]) }
    let(:state)       { { 'title' => 'Answer draft' } }
    let(:taskbar) do
      create(:taskbar, :with_new_knowledge_base_answer, user_id: editor.id, kb_locale: 'de-de', state:)
    end
    let(:query) do
      <<~QUERY
        query userCurrentTaskbarItemList($app: EnumTaskbarApp) {
          userCurrentTaskbarItemList(app: $app) {
            callback
            entityAccess
            entity {
              ... on UserTaskbarItemEntityKnowledgeBaseAnswerCreate {
                uid
                title
                locale
                visibility
              }
            }
          }
        }
      QUERY
    end

    before do
      taskbar
      gql.execute(query)
    end

    context 'when user is authenticated', authenticated_as: :editor do
      it 'returns the draft title, the tab id and the locale it is written in' do
        expect(gql.result.data.first).to include(
          'callback' => 'KnowledgeBaseAnswerCreate',
          'entity'   => include(
            'uid'    => taskbar.key.split('-', 2).last,
            'title'  => 'Answer draft',
            'locale' => 'de-de',
          ),
        )
      end

      # There is no record to authorize, but the state stands in for one - so the tab is not
      #   reported as inaccessible either.
      it 'reports the entity as granted' do
        expect(gql.result.data.first).to include('entityAccess' => 'Granted')
      end

      context 'without a title in the state' do
        let(:state) { {} }

        it 'returns an empty title' do
          expect(gql.result.data.first['entity']).to include('title' => '')
        end
      end

      # The state the draft would be created in, so the tab can show the same status icon a
      #   stored answer has.
      context 'with a visibility in the state' do
        let(:state) { { 'title' => 'Answer draft', 'visibility' => 'internal' } }

        it 'returns the state the answer would be created in' do
          expect(gql.result.data.first['entity']).to include('visibility' => 'internal')
        end
      end

      # A tab that has not been through a form updater round trip yet has no state to read it
      #   from, and the client falls back to the state a new answer starts in.
      context 'without a visibility in the state' do
        it 'returns no visibility' do
          expect(gql.result.data.first['entity']).to include('visibility' => nil)
        end
      end

      # Anything the enum does not know costs the tab its icon, not its title: a raise here would
      #   null the whole entity, leaving the tab without a label to render.
      context 'with a visibility the enum does not know' do
        let(:state) { { 'title' => 'Answer draft', 'visibility' => 'somewhat-public' } }

        it 'drops the visibility and keeps the rest of the entity' do
          expect(gql.result.data.first['entity']).to include(
            'visibility' => nil,
            'title'      => 'Answer draft',
          )
        end
      end
    end
  end
end
