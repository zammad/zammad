# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > User > Preview detailed information about user', type: :system, app: :mobile do
  let(:organization)        { create(:organization) }
  let(:user)                { create(:customer, firstname: 'Blanche', lastname: 'Devereaux', organization: organization, address: 'Berlin') }
  let(:group)               { create(:group) }
  let(:agent)               { create(:agent, groups: [group]) }

  def open_user
    visit "/users/#{user.id}"
    wait_for_gql('apps/mobile/entities/user/graphql/queries/user.graphql')
  end

  context 'when visiting as agent', authenticated_as: :agent do
    it 'shows general information' do
      open_user

      expect(page).to have_text(user.fullname)

      expect(find('section', text: %r{First name})).to have_text(user.firstname)
      expect(find('section', text: %r{Last name})).to have_text(user.lastname)
      expect(find('section', text: %r{Address})).to have_text(user.address)

      user.update!(firstname: 'Rose', lastname: 'Nylund', address: 'Hamburg')

      wait_for_gql('shared/graphql/subscriptions/userUpdates.graphql')

      expect(page).to have_text('Rose Nylund')

      expect(find('section', text: %r{First name})).to have_text('Rose')
      expect(find('section', text: %r{Last name})).to have_text('Nylund')
      expect(find('section', text: %r{Address})).to have_text('Hamburg')
    end
  end

  context 'when visiting as customer', authenticated_as: :user do
    it 'redirects to error' do
      visit '/users/1'
      expect_current_route('/error')
    end
  end
end
