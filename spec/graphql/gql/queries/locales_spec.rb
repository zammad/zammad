# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Locales, type: :graphql do

  context 'when fetching locales' do
    let(:agent)     { create(:agent) }
    let(:query)     { gql.read_files('shared/graphql/queries/locales.graphql') }
    let(:active)    { true }
    let(:variables) { { onlyActive: false } }
    let(:target_locale) do
      {
        'locale' => 'de-de',
        'alias'  => 'de',
        'name'   => 'Deutsch',
        'dir'    => 'ltr',
        'active' => active,
      }
    end

    before do
      gql.execute(query, variables: variables)
    end

    context 'with authenticated session', authenticated_as: :agent do
      it 'has data' do
        expect(gql.result.data).to include(target_locale)
      end

      context 'when fetching only active locales' do
        before do
          Locale.find_by(locale: 'de-de').update!(active: false)
        end

        let(:active)    { false }
        let(:variables) { { onlyActive: true } }

        it 'does not include inactive locales' do
          expect(gql.result.data).not_to include(target_locale)
        end
      end
    end

    context 'without authenticated session', authenticated_as: false do
      it 'has data' do
        expect(gql.result.data).to include(target_locale)
      end
    end
  end
end
