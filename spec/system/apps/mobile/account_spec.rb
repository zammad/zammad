# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App Account Page', app: :mobile, type: :system do
  context 'when on account page' do
    let(:admin) { create(:admin) }
    let(:agent) { create(:agent) }

    before do
      visit '/account'
    end

    context 'when updating locale', authenticated_as: :agent do
      it 'check that user can see and change locale' do
        locale = find_treeselect('Language')

        # current locale is visible
        expect(locale).to have_selected_option('English (United States)')

        locale.select_option('Dansk')
        wait_for_gql('apps/mobile/pages/account/graphql/mutations/locale.graphql')
        agent.reload
        expect(agent.preferences[:locale]).to eq('da')
      end
    end

    context 'when checking about information' do
      context 'when permitted', authenticated_as: :admin do
        it 'shows about information' do
          wait_for_gql('shared/graphql/queries/about.graphql')

          expect(page).to have_content(Version.get)
        end
      end

      context 'when forbidden', authenticated_as: :agent do
        it 'does not show about information' do
          expect(page).to have_no_content(Version.get)
        end
      end
    end
  end
end
