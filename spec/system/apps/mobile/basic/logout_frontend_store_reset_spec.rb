# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Basic > Logout Frontend Store Reset', app: :mobile, type: :system do
  context 'when use the logout and afterwards the login with a different user' do
    let(:agent)    { create(:agent) }
    let(:customer) { create(:customer) }

    it 'check that overviews are resetet for a different user', authenticated_as: :agent do
      visit '/'
      wait_for_gql 'shared/entities/ticket/graphql/queries/ticket/overviews.graphql'
      expect(find_all('a[href^="/mobile/tickets/view/"]').length).to eq(7)

      logout

      login(
        username: customer.login,
        password: 'test',
      )

      wait_for_gql 'shared/entities/ticket/graphql/queries/ticket/overviews.graphql'
      expect(find_all('a[href^="/mobile/tickets/view/"]').length).to eq(1)
    end
  end
end
