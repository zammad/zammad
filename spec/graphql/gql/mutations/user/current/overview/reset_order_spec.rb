# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::Overview::ResetOrder, :aggregate_failures, type: :graphql do
  context 'when resetting overview sortings' do
    let(:mutation) do
      <<~MUTATION
        mutation userCurrentOverviewResetOrder {
          userCurrentOverviewResetOrder {
            success
            overviews {
              id
              name
            }
            errors {
              message
              field
            }
          }
        }
      MUTATION
    end

    let(:agent)             { create(:agent) }
    let(:overview_sortings) { create_list(:'user/overview_sorting', 3, user: agent) }

    context 'with authenticated user having overview sortings', authenticated_as: :agent do
      it 'deletes all overview sortings' do
        overview_sortings
        expect { gql.execute(mutation) }.to change(User::OverviewSorting.where(user: agent), :count).by(-3)
      end

      it 'returns success' do
        gql.execute(mutation)

        expect(gql.result.data).to include('success' => true)
      end

      it 'triggers subscription' do
        allow(Gql::Subscriptions::User::Current::OverviewOrderingUpdates).to receive(:trigger_by)

        gql.execute(mutation)

        expect(Gql::Subscriptions::User::Current::OverviewOrderingUpdates)
          .to have_received(:trigger_by).with(agent)
      end
    end

    context 'with authenticated user having no overview sortings', authenticated_as: :agent do
      it 'does not delete any overview sortings' do
        expect { gql.execute(mutation) }.not_to change(User::OverviewSorting.where(user: agent), :count)
      end

      it 'returns success' do
        gql.execute(mutation)

        expect(gql.result.data).to include('success' => true)
      end
    end

    context 'with authenticated user having no permissions', authenticated_as: :agent do
      let(:agent) { create(:agent, roles: []) }

      it 'does not delete any overview sortings' do
        gql.execute(mutation)

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when unauthenticated' do
      before { gql.execute(mutation) }

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
