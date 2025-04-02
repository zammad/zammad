# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

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
end
