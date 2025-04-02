# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TaskbarItem::ListPrio, type: :graphql do
  context 'when sorting the taskbar item list for the logged-in user', authenticated_as: :agent do
    let(:agent)             { create(:agent) }
    let(:execute_query)     { true }
    let(:taskbar_item_list) { create_list(:taskbar, 3, user_id: agent.id) }
    let(:list) do
      taskbar_item_list.map do |taskbar_item|
        {
          id:   gql.id(taskbar_item),
          prio: Faker::Number.unique.between(from: 1, to: 10)
        }
      end
    end

    let(:query) do
      <<~QUERY
        mutation userCurrentTaskbarItemListPrio($list: [UserTaskbarItemListPrioInput!]!) {
          userCurrentTaskbarItemListPrio(list: $list) {
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

      gql.execute(query, variables: { list: list })
    end

    it 'sorts the taskbar item list by priority' do
      expect(taskbar_item_list.map { |item| item.reload.prio }).to eq(list.pluck(:prio))
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
