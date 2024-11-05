# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TaskbarItem::TouchLastContact, type: :graphql do
  context 'when touching last contact of a taskbar item for the logged-in user', authenticated_as: :agent do
    let(:agent)         { create(:agent) }
    let(:variables)     { { id: id } }
    let(:taskbar_item)  { create(:taskbar, user_id: agent.id) }
    let(:id)            { gql.id(taskbar_item) }

    let(:query) do
      <<~QUERY
        mutation userCurrentTaskbarItemTouchLastContact($id: ID!) {
          userCurrentTaskbarItemTouchLastContact(id: $id) {
            taskbarItem {
              id
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
      freeze_time
      taskbar_item
      travel(1.second)

      gql.execute(query, variables: variables)
    end

    context 'with existing taskbar item', :aggregate_failures do
      it 'returns the updated taskbar item' do
        expect(gql.result.data[:taskbarItem]).to eq(
          { 'id' => id }
        )
        expect(taskbar_item.reload.last_contact).to eq(Time.zone.now)
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
