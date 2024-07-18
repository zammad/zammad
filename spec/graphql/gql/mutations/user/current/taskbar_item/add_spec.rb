# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TaskbarItem::Add, :aggregate_failures, type: :graphql do
  context 'when adding a taskbar item for an user' do
    let(:mutation) do
      <<~MUTATION
        mutation userCurrentTaskbarItemAdd($input: UserTaskbarItemInput!) {
          userCurrentTaskbarItemAdd(input: $input) {
            taskbarItem {
              id
              key
            }
            errors {
              message
            }
          }
        }
      MUTATION
    end
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

    def execute_graphql_mutation
      gql.execute(mutation, variables: { input: input })
    end

    context 'when user is not authenticated' do
      it 'returns an error' do
        execute_graphql_mutation

        expect(gql.result.error_message).to eq('Authentication required')
      end
    end

    context 'when user is authenticated', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      it 'adds a taskbar item' do
        expect { execute_graphql_mutation }.to change(Taskbar, :count).by(1)
      end
    end
  end
end
