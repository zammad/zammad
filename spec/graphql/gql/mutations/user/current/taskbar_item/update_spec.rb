# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
