# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Locales, type: :graphql do

  context 'when fetching locales' do
    let(:agent) { create(:agent) }
    let(:query) { read_graphql_file('common/graphql/queries/locales.graphql') }
    let(:target_locale) do
      {
        'locale' => 'de-de',
        'alias'  => 'de',
        'name'   => 'Deutsch',
        'dir'    => 'ltr',
        'active' => true,
      }
    end

    before do
      graphql_execute(query)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(graphql_response['data']['locales']).to include(target_locale)
      end
    end

    context 'without authenticated session', authenticated_as: false do
      it 'has data' do
        expect(graphql_response['data']['locales']).to include(target_locale)
      end
    end
  end
end
