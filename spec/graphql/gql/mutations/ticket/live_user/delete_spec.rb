# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::LiveUser::Delete, :aggregate_failures, type: :graphql do

  context 'when deleting live user entry', authenticated_as: :agent do
    let(:agent)           { create(:agent, groups: [ticket.group]) }
    let(:ticket)          { create(:ticket) }
    let(:live_user_entry) { create(:taskbar, key: "Ticket-#{ticket.id}", user: agent, app: 'mobile') }

    let(:query) do
      <<~QUERY
        mutation ticketLiveUserDelete($id: ID!, $app: EnumTaskbarApp!) {
          ticketLiveUserDelete(id: $id, app: $app) {
            success
            errors {
              message
              field
            }
          }
        }
      QUERY
    end

    let(:variables) { { id: gql.id(ticket), app: 'mobile' } }

    before do
      live_user_entry
      gql.execute(query, variables: variables)
    end

    context 'when live user entry does exist' do
      it 'does delete' do
        expect(live_user_entry.class).not_to be_exist(live_user_entry.id)
      end

      it 'returns success' do
        expect(gql.result.data['success']).to be true
      end
    end

    context 'when live user entry does not exist (user id mismatch)' do
      let(:live_user_entry) { create(:taskbar, key: "Ticket-#{ticket.id}", user: User.find(1)) }

      it 'does not delete' do
        expect(live_user_entry.class).to be_exist(live_user_entry.id)
      end
    end

    context 'when live user entry does not exist (app mismatch)' do
      let(:live_user_entry) { create(:taskbar, key: "Ticket-#{ticket.id}", user: agent, app: 'desktop') }

      it 'does not delete' do
        expect(live_user_entry.class).to be_exist(live_user_entry.id)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
