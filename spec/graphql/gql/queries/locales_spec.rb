# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Locales, type: :graphql do

  context 'when fetching locales' do
    let(:agent)     { create(:agent) }
    let(:query)     do
      <<~QUERY
        query locales($onlyActive: Boolean = false) {
          locales(onlyActive: $onlyActive) {
            locale
            alias
            name
            dir
            active
          }
        }
      QUERY
    end
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
        let(:active)    { false }
        let(:variables) do
          Locale.find_by(locale: 'de-de').update!(active: false)
          { onlyActive: true }
        end

        it 'does not include inactive locales' do
          expect(gql.result.data.select { |e| e['locale'] == 'de-de' }).to eq([])
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
