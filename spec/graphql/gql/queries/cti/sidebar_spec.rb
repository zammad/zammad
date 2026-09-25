# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Which calls a user gets to see is covered by spec/services/service/cti/log/list_spec.rb, what counts as
#   unhandled or ringing by spec/models/cti/log_spec.rb — this covers the GraphQL surface only.
RSpec.describe Gql::Queries::Cti::Sidebar, type: :graphql do
  let(:query) do
    <<~GQL
      query ctiSidebar {
        ctiSidebar {
          unhandledCount
          ringingCalls {
            id
            state
            done
            fromPretty
            fromMatches { level user { id fullname } }
          }
        }
      }
    GQL
  end
  let(:customer) { create(:customer, firstname: 'Franz', lastname: 'Bauer') }
  let(:ringing) do
    create(:cti_log, :inbound, :ringing, from: '4930609854180', preferences: { from: [{ level: 'known', user_id: customer.id }] })
  end
  let(:logs) do
    [
      ringing,
      create(:cti_log, :inbound, :not_reached),
      create(:cti_log, :inbound, :handled, :done),
    ]
  end

  before do
    logs
    gql.execute(query)
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent) }

    it 'counts the calls not marked as done' do
      expect(gql.result.data['unhandledCount']).to eq(2)
    end

    it 'returns the ringing calls with their fields' do
      expect(gql.result.data['ringingCalls']).to eq([
                                                      {
                                                        'id'          => gql.id(ringing),
                                                        'state'       => 'newCall',
                                                        'done'        => false,
                                                        'fromPretty'  => '+49 30 609854180',
                                                        'fromMatches' => [{ 'level' => 'known', 'user' => { 'id' => gql.id(customer), 'fullname' => 'Franz Bauer' } }],
                                                      },
                                                    ])
    end

    context 'with several ringing calls' do
      let(:newer_calls) { create_list(:cti_log, 6, :inbound, :ringing) }
      let(:logs)        { super() + newer_calls }

      it 'returns all of them, newest first' do
        expect(gql.result.data['ringingCalls'].pluck('id')).to eq((newer_calls.reverse + [ringing]).map { |log| gql.id(log) })
      end
    end

    # The old navigation shows only what its caller log list, capped at the view limit, holds;
    #   the counter is deliberately not cut off there.
    context 'with more entries than the view limit' do
      let(:logs) do
        older = travel_to(1.minute.ago) { [create(:cti_log, :inbound, :ringing), create(:cti_log, :inbound, :not_reached)] }

        older + create_list(:cti_log, Cti::Log.view_limit, :inbound, :handled, :done)
      end

      it 'still counts the calls beyond it, but does not list them as ringing', :aggregate_failures do
        expect(gql.result.data['unhandledCount']).to eq(2)
        expect(gql.result.data['ringingCalls']).to be_empty
      end
    end

    context 'when a notify map places the calls in another agent\'s queue' do
      let(:logs) do
        cti_config = Setting.get('cti_config')
        cti_config[:notify_map] = [{ queue: 'queue2', user_ids: [create(:agent).id.to_s] }]
        Setting.set('cti_config', cti_config)

        super()
      end

      it 'sees none of them', :aggregate_failures do
        expect(gql.result.data['unhandledCount']).to eq(0)
        expect(gql.result.data['ringingCalls']).to be_empty
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
