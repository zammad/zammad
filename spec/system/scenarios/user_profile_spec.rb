# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_user_profile_test.rb. Modal editing incl. task
#   title updates is covered by scenarios/user_access_permissions_spec.rb, the
#   ticket linkage by 'when ticket changes in user profile' in user/profile_spec.
#   This file keeps the user specific remainders: opening via the global search,
#   the inline note round-tripping into the edit modal and the note sync into a
#   second open session.
RSpec.describe 'Scenario > User profile', authenticated_as: :authenticate, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:agent)    { create(:agent, password: 'test', groups: [group]) }
  let(:customer) { create(:customer, firstname: 'Nicole', lastname: 'Braun') }

  def authenticate
    customer

    agent
  end

  def open_user_via_search
    find('#global-search').fill_in with: customer.lastname

    expect(page).to have_css('.global-search-result', text: customer.fullname)

    within '.global-search-result' do
      first(:link, customer.fullname).click
    end
  end

  it 'opens via search and round-trips the inline note into the edit modal' do
    visit 'dashboard'

    open_user_via_search

    expect(page).to have_css('.tasks-navigation', text: customer.fullname)
    expect(page).to have_css('.content.active .profile-window', text: customer.email)

    find('.content.active .profile [data-name="note"]').send_keys 'some note 123'
    find('.content.active .profile-window h1').click

    expect(customer.reload.note).to include('some note 123')

    within(:active_content) do
      click '.js-action .icon-arrow-down'
      click '.js-action [data-type="edit"]'
    end

    in_modal do
      expect(page).to have_css('[data-name="note"]', text: 'some note 123')

      click_on 'Cancel'
    end
  end

  it 'syncs an inline note change into a second open session' do
    visit "#user/profile/#{customer.id}"

    using_session(:second_browser) do
      login(username: create(:agent, password: 'test', groups: [group]).login, password: 'test')

      visit "#user/profile/#{customer.id}"
    end

    find('.content.active .profile [data-name="note"]').send_keys 'some realtime note'
    find('.content.active .profile-window h1').click

    using_session(:second_browser) do
      within '.content.active .profile-window' do
        expect(page).to have_text('some realtime note')
      end
    end
  end
end
