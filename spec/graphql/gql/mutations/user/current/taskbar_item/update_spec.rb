# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TaskbarItem::Update, type: :graphql do
  context 'when updating a taskbar item for the logged-in user', authenticated_as: :agent do
    let(:agent)         { create(:agent) }
    let(:variables)     { { id: id, input: input } }
    let(:execute_query) { true }
    let(:taskbar_item)  { create(:taskbar, user_id: agent.id) }
    let(:input) do
      {
        key:      'key',
        callback: 'TicketZoom',
        params:   {},
        prio:     1,
        notify:   false,
        app:      'desktop'
      }
    end
    let(:id) { gql.id(taskbar_item) }

    let(:query) do
      <<~QUERY
        mutation userCurrentTaskbarItemUpdate($id: ID!, $input: UserTaskbarItemInput!) {
          userCurrentTaskbarItemUpdate(id: $id, input: $input) {
            taskbarItem {
              app
              key
            }
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    before do
      next if !execute_query

      gql.execute(query, variables: variables)
    end

    context 'with existing taskbar item', :aggregate_failures do
      it 'returns the updated taskbar item' do
        expect(taskbar_item.reload.key).to eq('key')
        expect(gql.result.data[:taskbarItem]).to eq(
          { 'app' => 'desktop', 'key' => 'key' }
        )
      end
    end

    context 'with not existing taskbar item' do
      let(:id) { Gql::ZammadSchema.id_from_internal_id(Taskbar, Faker::Number.unique.number) }

      it 'fails with error' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    context 'when updating another user\'s taskbar item' do
      let(:other_user)    { create(:agent) }
      let(:taskbar_item)  { create(:taskbar, user_id: other_user.id) }
      let(:execute_query) { false }

      it 'raises forbidden error and does not mutate the record', :aggregate_failures do
        original_attributes = taskbar_item.attributes

        gql.execute(query, variables: { id: gql.id(taskbar_item), input: input })

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        expect(taskbar_item.reload.attributes).to eq(original_attributes)
      end
    end

    context 'when updating another agent\'s taskbar item' do
      let(:other_agent)   { create(:agent) }
      let(:taskbar_item)  { create(:taskbar, user: other_agent) }
      let(:execute_query) { false }

      it 'raises forbidden error' do
        gql.execute(query, variables: { id: gql.id(taskbar_item), input: input })
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
