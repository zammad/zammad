# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::TaskbarItem::TouchLastContact, type: :graphql do
  context 'when touching last contact of a taskbar item for the logged-in user', authenticated_as: :agent do
    let(:agent)         { create(:agent) }
    let(:variables)     { { id: id } }
    let(:taskbar_item)  { create(:taskbar, :with_user, user: agent) }
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
    end

    def execute
      gql.execute(query, variables:)
    end

    context 'with existing taskbar item', :aggregate_failures do
      context 'with taskbar item without a related object' do
        let(:taskbar_item)  { create(:taskbar) }

        it 'returns the updated taskbar item' do
          execute

          expect(gql.result.data[:taskbarItem]).to eq(
            { 'id' => id }
          )
          expect(taskbar_item.reload.last_contact).to eq(Time.zone.now)
        end

        it 'does not call mark as seen service' do
          allow(OnlineNotification).to receive(:mark_as_seen!)
          execute
          expect(OnlineNotification).not_to have_received(:mark_as_seen!)
        end
      end

      context 'with taskbar item with a related object' do
        it 'returns the updated taskbar item' do
          execute

          expect(gql.result.data[:taskbarItem]).to eq(
            { 'id' => id }
          )
          expect(taskbar_item.reload.last_contact).to eq(Time.zone.now)
        end

        it 'marks the related object as seen' do
          allow(OnlineNotification).to receive(:mark_as_seen!)

          execute

          expect(OnlineNotification).to have_received(:mark_as_seen!).with(agent, agent)
        end
      end
    end

    context 'with not existing taskbar item' do
      let(:id) { Gql::ZammadSchema.id_from_internal_id(Taskbar, Faker::Number.unique.number) }

      it 'fails with error' do
        execute
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated' do
      before { execute }
    end
  end
end
