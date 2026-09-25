# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The behavior is covered by spec/services/service/cti/log/done_update_spec.rb —
#   this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::Cti::Log::DoneUpdate, type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation ctiLogDoneUpdate($id: ID!, $done: Boolean!) {
        ctiLogDoneUpdate(id: $id, done: $done) {
          log {
            id
            done
          }
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:log)       { create(:cti_log, done: false) }
  let(:variables) { { id: gql.id(log), done: true } }

  before do
    gql.execute(mutation, variables:)
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'returns the call as handled' do
      expect(gql.result.data['log']).to eq('id' => gql.id(log), 'done' => true)
    end

    context 'when clearing the flag' do
      let(:log)       { create(:cti_log, done: true) }
      let(:variables) { { id: gql.id(log), done: false } }

      it 'returns the call as not handled' do
        expect(gql.result.data['log']).to include('done' => false)
      end
    end

    context 'when the call is not in the agent\'s caller log' do
      # The outer before hook already executes the mutation, so the notify map
      #   is configured while the call is created for its variables.
      let(:log) do
        cti_config = Setting.get('cti_config')
        cti_config[:notify_map] = [{ queue: 'queue2', user_ids: [create(:agent).id.to_s] }]
        Setting.set('cti_config', cti_config)

        create(:cti_log, queue: 'queue2')
      end

      it 'responds with a forbidden error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when the call does not exist' do
      let(:variables) { { id: Gql::ZammadSchema.id_from_internal_id('Cti::Log', 1337), done: true } }

      it 'responds with an error' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end
  end

  context 'with a user without the cti.agent permission', authenticated_as: :user do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
