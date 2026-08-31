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

      # A tab that has not been through a form updater round trip yet has no state to read it from,
      #   and a new answer starts out as a draft.
      context 'without a visibility in the state' do
        it 'returns the state a new answer starts in' do
          expect(gql.result.data.first['entity']).to include('visibility' => 'draft')
        end
      end

      # Anything the enum does not know costs the tab its icon, not its title: a raise here would
      #   null the whole entity, leaving the tab without a label to render.
      context 'with a visibility the enum does not know' do
        let(:state) { { 'title' => 'Answer draft', 'visibility' => 'somewhat-public' } }

        it 'falls back to draft and keeps the rest of the entity' do
          expect(gql.result.data.first['entity']).to include(
            'visibility' => 'draft',
            'title'      => 'Answer draft',
          )
        end
      end
    end
  end

  # An edit tab points at the answer itself, so its entity is resolved and authorized through the
  #   generic record path - only the query it is authorized with differs.
  context 'when listing a knowledge base answer edit item' do
    let(:answer)      { create(:knowledge_base_answer, :internal) }
    let(:editor_role) { create(:role, permission_names: 'knowledge_base.editor') }
    let(:editor)      { create(:user, roles: [editor_role]) }
    let(:reader_role) { create(:role, permission_names: 'knowledge_base.reader') }
    let(:reader)      { create(:user, roles: [reader_role]) }
    let(:user)        { editor }
    let(:taskbar) do
      create(:taskbar, :with_knowledge_base_answer, answer:, kb_locale: 'de-de', user_id: user.id)
    end
    let(:query) do
      <<~QUERY
        query userCurrentTaskbarItemList($app: EnumTaskbarApp) {
          userCurrentTaskbarItemList(app: $app) {
            callback
            key
            entityAccess
            entity {
              ... on KnowledgeBaseAnswer {
                id
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

    context 'when the user may edit the answer', authenticated_as: :editor do
      it 'resolves the answer of the key, its locale qualifier notwithstanding' do
        expect(gql.result.data.first).to include(
          'callback'     => 'KnowledgeBaseAnswerEdit',
          'key'          => "KnowledgeBase__Answer-#{answer.id}-de-de",
          'entityAccess' => 'Granted',
          'entity'       => include('id' => Gql::ZammadSchema.id_from_object(answer)),
        )
      end

      # The tab of a deleted answer is closed with it (HasTaskbars#destroy_taskbars), so what is
      #   left is a key that never resolved: a stale link, or a client of another session.
      context 'when the key names an answer that does not exist' do
        let(:taskbar) do
          create(:taskbar, :with_knowledge_base_answer, answer:, kb_locale: 'de-de', user_id: user.id,
                 key: "KnowledgeBase__Answer-#{answer.id + 1_000}-de-de")
        end

        it 'reports the entity as not found' do
          expect(gql.result.data.first).to include('entityAccess' => 'NotFound', 'entity' => nil)
        end
      end
    end

    # #show? passes for a reader of the category, which is why the edit tab asks #update? instead
    #   (see Taskbar.entity_pundit_method) - otherwise it would report an entity the edit view
    #   refuses as accessible.
    context 'when the user may only read the answer', authenticated_as: :reader do
      let(:user) { reader }

      it 'reports the entity as forbidden' do
        expect(gql.result.data.first).to include('entityAccess' => 'Forbidden', 'entity' => nil)
      end
    end
  end
end
