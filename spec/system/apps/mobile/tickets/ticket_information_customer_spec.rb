# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Ticket > Customer > Preview customer information', app: :mobile, type: :system do
  let(:organization)        { create(:organization) }
  let(:user)                { create(:customer, firstname: 'Blanche', lastname: 'Devereaux', organization: organization, address: 'Berlin') }
  let(:ticket)              { create(:ticket, customer: user, group: group) }
  let(:group)               { create(:group) }
  let(:agent)               { create(:agent, groups: [group]) }

  def open_user
    visit "/tickets/#{ticket.id}/information/customer"
    wait_for_gql('shared/entities/object-attributes/graphql/queries/objectManagerFrontendAttributes.graphql')
    wait_for_gql('apps/mobile/entities/user/graphql/queries/user.graphql')
    wait_for_gql('apps/mobile/pages/ticket/graphql/queries/ticket.graphql')
  end

  context 'when visiting as agent', authenticated_as: :agent do
    it 'shows general information' do
      open_user

      expect(page).to have_text(ticket.title)
      expect(page).to have_text(user.fullname)

      expect(find('section', text: %r{Address})).to have_text(user.address)

      expect(page).to have_text('Edit Customer')

      user.update!(firstname: 'Rose', lastname: 'Nylund')

      wait_for_gql('shared/graphql/subscriptions/userUpdates.graphql')

      expect(page).to have_text('Rose Nylund')
    end

    it 'can load all secondary organizations' do
      organizations = create_list(:organization, 5)
      user.update(organizations: organizations)

      open_user

      expect(page).to have_text(organizations[0].name)
      expect(page).to have_text(organizations[1].name)
      expect(page).to have_text(organizations[2].name)
      expect(page).to have_no_text(organizations[3].name)

      click('button', text: 'Show 2 more')

      wait_for_gql('apps/mobile/entities/user/graphql/queries/user.graphql', number: 2)

      expect(page).to have_text(organizations[3].name)
      expect(page).to have_text(organizations[4].name)
    end
  end

  context 'when visiting as customer', authenticated_as: :user do
    it 'user is redirected to error' do
      visit "/tickets/#{ticket.id}/information/customer"

      expect_current_route('/error')
    end
  end
end
