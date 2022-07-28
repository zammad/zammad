# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > App Account Page', type: :system, app: :mobile do
  context 'when on account page', authenticated_as: :admin do
    let(:admin) { create(:admin) }

    before do
      visit '/account'
    end

    context 'when updating locale' do
      it 'check that user can see and change locale' do
        # current locale is visible
        expect(page).to have_content('English')

        click('output', text: %r{English}i)
        click('span', text: %r{Dansk}i)
        wait_for_gql('apps/mobile/modules/account/graphql/mutations/locale.graphql')
        admin.reload
        expect(admin.preferences[:locale]).to eq('da')
      end
    end
  end
end
