# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Product::About, type: :graphql do
  context 'when fetching product about' do
    let(:query) do
      <<~QUERY
        query productAbout {
          productAbout
        }
      QUERY
    end

    context 'when authorized', authenticated_as: :admin do
      let(:admin) { create(:admin) }

      before do
        gql.execute(query)
      end

      it 'returns data' do
        expect(gql.result.data).to eq(Version.get)
      end
    end

    context 'when not authorized', authenticated_as: :agent do
      let(:agent) { create(:agent) }

      before do
        gql.execute(query)
      end

      it_behaves_like 'graphql responds with error if unauthenticated'
    end
  end
end
