# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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

    context 'when deleting another agent\'s taskbar item' do
      let(:other_agent)   { create(:agent) }
      let(:taskbar_item)  { create(:taskbar, user: other_agent) }
      let(:execute_query) { false }

      before do
        gql.execute(query, variables: { id: gql.id(taskbar_item) })
      end

      it 'raises forbidden error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end

      it 'does not delete the taskbar item' do
        expect(Taskbar.exists?(taskbar_item.id)).to be(true)
      end
    end

    context 'when deleting another user\'s taskbar item' do
      let(:other_user)    { create(:agent) }
      let(:taskbar_item)  { create(:taskbar, user_id: other_user.id) }
      let(:execute_query) { false }

      before do
        gql.execute(query, variables: { id: gql.id(taskbar_item) })
      end

      it 'raises forbidden error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end

      it 'does not delete the taskbar item' do
        expect(Taskbar.exists?(taskbar_item.id)).to be(true)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
