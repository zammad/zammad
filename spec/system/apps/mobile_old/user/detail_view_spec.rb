# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > User > Preview detailed information about user', app: :mobile, type: :system do
  let(:organization)        { create(:organization) }
  let(:user)                { create(:customer, firstname: 'Blanche', lastname: 'Devereaux', organization: organization, address: 'Berlin') }
  let(:group)               { create(:group) }
  let(:agent)               { create(:agent, groups: [group]) }

  def open_user
    visit "/users/#{user.id}"
    wait_for_query('user')
    wait_for_subscription_start('userUpdates')
  end

  context 'when visiting as agent', authenticated_as: :agent do
    it 'shows general information' do
      open_user

      expect(page).to have_text(user.fullname)

      expect(find('section', text: %r{Address})).to have_text(user.address)

      user.update!(firstname: 'Rose', lastname: 'Nylund', address: 'Hamburg')

      expect(page).to have_text('Rose Nylund')

      expect(find('section', text: %r{Address})).to have_text('Hamburg')
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

      wait_for_query('user', number: 2)

      expect(page).to have_text(organizations[3].name)
      expect(page).to have_text(organizations[4].name)
    end
  end

  context 'when visiting as customer', authenticated_as: :user do
    it 'redirects to error' do
      visit '/users/1'
      expect_current_route('/error')
    end
  end

  it 'can open ticket create form' do
    open_user

    click_on 'Create new ticket for this user'
    expect_current_route("/tickets/create?customer_id=#{user.id}")

    within_form(form_updater_gql_number: 1) do
      find_input('Title').type(Faker::Name.unique.name_with_middle)

      # open "additional information" step
      find_button('Continue').click
      find_button('Continue').click

      expect(find_autocomplete('Customer')).to have_selected_option(user.fullname)
    end
  end
end
