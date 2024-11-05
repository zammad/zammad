# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TaskbarItem::Delete, type: :graphql do
  context 'when deleting a taskbar item for the logged-in user', authenticated_as: :agent do
    let(:agent)         { create(:agent) }
    let(:variables)     { { id: gql.id(taskbar_item) } }
    let(:execute_query) { true }
    let(:taskbar_item)  { create(:taskbar, user_id: agent.id) }

    let(:query) do
      <<~QUERY
        mutation userCurrentTaskbarItemDelete($id: ID!) {
          userCurrentTaskbarItemDelete(id: $id) {
            success
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

    context 'with existing taskbar item' do
      it 'returns success' do
        expect(gql.result.data[:success]).to be true
      end

      it 'does not find the taskbar item anymore' do
        expect { Taskbar.find(taskbar_item.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'with not existing taskbar item', :aggregate_failures do
      let(:variables) do
        { id: Gql::ZammadSchema.id_from_internal_id(Taskbar, Faker::Number.unique.number) }
      end

      it 'fails with error' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
