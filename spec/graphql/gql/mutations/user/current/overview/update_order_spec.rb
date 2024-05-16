# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::Overview::UpdateOrder, :aggregate_failures, type: :graphql do
  let(:mutation) do
    <<~MUTATION
      mutation userCurrentOverviewUpdateOrder($overviewIds: [ID!]!) {
        userCurrentOverviewUpdateOrder(overviewIds: $overviewIds) {
          success
          errors {
            message
            field
          }
        }
      }
    MUTATION
  end

  let(:user)                  { create(:agent) }
  let(:overview_1)            { create(:overview, prio: 1) }
  let(:overview_2)            { create(:overview, prio: 2) }
  let(:overview_inaccessible) { create(:overview, prio: 3, roles: Role.where(name: 'Customer')) }
  let(:overviews)             { [overview_1, overview_2] }
  let(:variables)             { { overviewIds: overviews.map { |elem| gql.id(elem) } } }

  before do
    Overview.destroy_all

    [overview_1, overview_2].each do |elem|
      elem.users << user
    end

    overview_inaccessible
  end

  context 'with authenticated user', authenticated_as: :user do
    context 'when multiple overviews order given' do
      let(:overviews) { [overview_2, overview_1] }

      it 'saves given order' do
        execute_mutation

        expect(user.overview_sortings).to contain_exactly(
          have_attributes(overview: overview_1, prio: 1),
          have_attributes(overview: overview_2, prio: 0),
        )
      end

      it 'triggers subscription' do
        allow(Gql::Subscriptions::User::Current::OverviewOrderingUpdates).to receive(:trigger_by)

        execute_mutation

        expect(Gql::Subscriptions::User::Current::OverviewOrderingUpdates)
          .to have_received(:trigger_by).with(user)
      end
    end

    context 'when inaccesible overview is given too' do
      let(:overviews) { [overview_2, overview_1, overview_inaccessible] }

      it 'saves given order' do
        execute_mutation

        expect(user.overview_sortings).to contain_exactly(
          have_attributes(overview: overview_1, prio: 1),
          have_attributes(overview: overview_2, prio: 0),
        )
      end
    end
  end

  context 'with authenticated user having no permissions', authenticated_as: :user do
    let(:user) { create(:agent, roles: []) }

    it 'does not delete any overview sortings' do
      execute_mutation

      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when unauthenticated' do
    before { execute_mutation }

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  def execute_mutation
    gql.execute(mutation, variables:)
  end
end
