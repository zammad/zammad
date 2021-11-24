# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Locales, type: :request do

  context 'when fetching locales' do
    let(:agent) { create(:agent) }
    let(:query) { File.read(Rails.root.join('app/frontend/common/graphql/queries/locales.graphql')) }
    let(:graphql_response) do
      post '/graphql', params: { query: query }, as: :json
      json_response
    end
    let(:target_locale) do
      {
        'locale' => 'de-de',
        'alias'  => 'de',
        'name'   => 'Deutsch',
        'dir'    => 'ltr',
        'active' => true,
      }
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
