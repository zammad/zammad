# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe GraphqlChannel, type: :channel do
  class TestQuery < Gql::Queries::BaseQuery # rubocop:disable RSpec/LeakyConstantDeclaration, Lint/ConstantDefinitionInBlock
    type Gql::Types::UserType, null: true

    def resolve
      User.find_by id: UserInfo.current_user_id
    end
  end

  let(:query) do
    <<~QUERY
      query testQuery {
        testQuery {
          id
        }
      }
    QUERY
  end

  # https://github.com/zammad/zammad/issues/5401
  describe 'setting UserInfo.current_user_id thread variable' do
    context 'when connected with a session with a user' do
      let(:user) { create(:agent) }

      it 'sets UserInfo.current_user_id for the operation' do
        stub_connection sid: '123_456', current_user: user, still_authorized?: true

        subscribe

        perform :execute, operationName: 'testQuery', query: query

        expect(transmissions.last).to include(
          result: include(
            data: include(testQuery: include(id: user.to_global_id.to_s))
          )
        )
      end
    end

    context 'when connected with a userless session' do
      it 'sets UserInfo.current_user_id for the operation' do
        stub_connection sid: '123_456', current_user: nil, still_authorized?: true

        subscribe

        perform :execute, operationName: 'testQuery', query: query

        expect(transmissions.last).to include(
          result: include(
            data: include(testQuery: be_nil)
          )
        )
      end
    end
  end

  describe 'originating browser tab' do
    let(:captured) { {} }

    before do
      allow(Gql::ZammadSchema).to receive(:execute).and_wrap_original do |method, **kwargs|
        captured[:origin]         = Gql::SubscriptionOrigin.current
        captured[:browser_tab_id] = kwargs[:context][:browser_tab_id]
        method.call(**kwargs)
      end

      stub_connection sid: '123_456', current_user: create(:agent), still_authorized?: true

      subscribe browserTabId: 'tab-a', skipSubscriptions: %w[userCurrentTaskbarItemStateUpdates]

      perform :execute, query: '{ __typename }'
    end

    it 'applies it to the execution' do
      expect(captured[:origin]).to have_attributes(
        browser_tab_id:     'tab-a',
        skip_subscriptions: %w[userCurrentTaskbarItemStateUpdates],
      )
    end

    it 'identifies the subscriber by it' do
      expect(captured[:browser_tab_id]).to eq('tab-a')
    end
  end

  # Whether the connection may still be served is the connection's decision (see
  #   ApplicationCable::Connection#still_authorized?), the channel only follows it.
  describe 'when the connection is no longer authorized' do
    let(:user) { create(:agent) }
    let(:current_user_query) do
      <<~QUERY
        query currentUser {
          currentUser {
            id
          }
        }
      QUERY
    end

    before do
      stub_connection sid: '123_456', current_user: user, still_authorized?: still_authorized

      subscribe

      perform :execute, operationName: 'currentUser', query: current_user_query
    end

    context 'when the connection is still authorized' do
      let(:still_authorized) { true }

      it 'serves the operation as the user' do
        expect(transmissions.last).to include(
          result: include(
            data: include(currentUser: include(id: user.to_global_id.to_s))
          )
        )
      end
    end

    context 'when the connection is no longer authorized' do
      let(:still_authorized) { false }

      it 'serves the operation as logged out' do
        expect(transmissions.last).to include(
          result: include(
            errors: include(include(message: 'Authentication required'))
          )
        )
      end
    end
  end

  # The connection's origin check covers the form updater here, which over HTTP needs the CSRF token.
  describe 'running the form updater' do
    let(:query) do
      <<~QUERY
        query formUpdater($meta: FormUpdaterMetaInput!) {
          formUpdater(formUpdaterId: FormUpdater__Updater__Ticket__Create, relationFields: [], meta: $meta, data: {}) {
            fields
          }
        }
      QUERY
    end

    before do
      # Outside of tests, a request without a controller is not let through on that ground.
      allow(Rails.env).to receive(:test?).and_return(false)

      stub_connection sid: '123_456', current_user: create(:agent), still_authorized?: true

      subscribe
    end

    it 'needs no CSRF token' do
      perform :execute, operationName: 'formUpdater', query:, variables: { meta: { formId: SecureRandom.uuid } }

      expect(transmissions.last).to include(result: include(data: include(formUpdater: include(fields: be_present))))
    end
  end
end
