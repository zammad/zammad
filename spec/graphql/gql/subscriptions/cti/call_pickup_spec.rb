# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Which view is resolved is decided by Service::Cti::Log::ResolvePickupTarget and covered in its spec, the
#   guards of the push by spec/models/cti/driver/base_spec.rb — this covers the subscription surface only:
#   the payload, the per-user scope, the caller notification gate and authorization.
RSpec.describe Gql::Subscriptions::Cti::CallPickup, type: :graphql do
  let(:subscription) do
    <<~QUERY
      subscription ctiCallPickup {
        ctiCallPickup {
          target {
            view
            customer {
              id
            }
            log {
              id
              fromPretty
            }
          }
        }
      }
    QUERY
  end
  let(:mock_channel) { build_mock_channel }

  let(:customer) { create(:customer, phone: '+49 30 609854180') }
  let(:call)     { { 'direction' => 'in', 'from' => '4930609854180', 'to' => '4930609811111', 'call_id' => '4711' } }

  def process(event, params = {})
    Cti::Driver::Base.new(params: call.merge('event' => event).merge(params).with_indifferent_access, config: {}).process
  end

  before do
    customer
    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'with an agent', authenticated_as: :agent do
    let(:agent) { create(:agent, preferences: { cti: true }) }

    it 'subscribes without an initial payload' do
      expect(gql.result.data).to eq({ 'target' => nil })
    end

    it 'receives the resolved target when picking up' do
      create(:ticket, customer:)
      process('newCall')
      process('answer', 'user_id' => agent.id)

      expect(mock_channel.mock_broadcasted_first.data['target']).to eq(
        'view'     => 'userDetail',
        'customer' => { 'id' => gql.id(customer) },
        'log'      => { 'id' => gql.id(Cti::Log.last), 'fromPretty' => '+49 30 609854180' },
      )
    end

    it 'carries no customer when none was detected' do
      process('newCall', 'from' => '4930609854199')
      process('answer', 'from' => '4930609854199', 'user_id' => agent.id)

      expect(mock_channel.mock_broadcasted_first.data['target']).to include('view' => 'ticketCreate', 'customer' => nil)
    end

    it 'receives nothing while the call is still ringing' do
      process('newCall')

      expect(mock_channel.mock_broadcasted_messages).to be_empty
    end

    it 'receives nothing when another agent picks up' do
      process('newCall')
      process('answer', 'user_id' => create(:agent, preferences: { cti: true }).id)

      expect(mock_channel.mock_broadcasted_messages).to be_empty
    end

    context 'with the caller notification switched off' do
      let(:agent) { create(:agent) }

      it 'receives nothing' do
        process('newCall')
        process('answer', 'user_id' => agent.id)

        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end
  end

  # Both views a pickup opens need the ticket agent permission, so a phone agent without it
  #   is kept off the subscription altogether.
  context 'with a user whose role holds cti.agent only', authenticated_as: :user do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'cti.agent')], preferences: { cti: true }) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
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
