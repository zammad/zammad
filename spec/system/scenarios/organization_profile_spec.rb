# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_organization_profile_test.rb as end-to-end scenarios:
#   opening an organization via the global search incl. task tab title, inline note
#   editing, renaming via the edit modal, the member avatar active/inactive cycle and
#   the note sync into a second open session. Ticket linkage into the profile is
#   covered by 'when ticket changes in organization profile' in organization_profile_spec.
RSpec.describe 'Scenario > Organization profile', authenticated_as: :authenticate, type: :system do
  let(:group)        { Group.find_by(name: 'Users') }
  let(:agent)        { create(:agent, password: 'test', groups: [group]) }
  let(:organization) { create(:organization, name: 'Ported Profile Org') }
  let(:member)       { create(:customer, firstname: 'Nicole', lastname: 'Braun', organization: organization) }

  def authenticate
    member

    agent
  end

  def open_organization_via_search
    find('#global-search').fill_in with: organization.name

    expect(page).to have_css('.global-search-result', text: organization.name)

    within '.global-search-result' do
      click_on organization.name
    end
  end

  it 'opens via search, edits the note inline and renames via the edit modal' do
    visit 'dashboard'

    open_organization_via_search

    # The profile opens as a task with the organization title and shows note + members.
    expect(page).to have_css('.tasks-navigation', text: organization.name)
    expect(page).to have_css('.content.active .profile-window [data-name="note"]')
    expect(page).to have_css('.content.active .profile-window', text: member.fullname)

    # The note is editable inline.
    find('.content.active .profile [data-name="note"]').send_keys 'some note 123'
    find('.content.active .profile-window h1').click

    expect(organization.reload.note).to include('some note 123')

    # Renaming via the edit modal updates profile and task title.
    within(:active_content) do
      click '.js-action .icon-arrow-down'
      click '.js-action [data-type="edit"]'
    end

    in_modal do
      expect(page).to have_css('[data-name="note"]', text: 'some note 123')

      fill_in 'name', with: 'Ported Profile Org Z2'
      find('[data-name="note"]').send_keys ' some note abc'

      click_on 'Submit'
    end

    within(:active_content) do
      expect(page).to have_css('.profile-window', text: 'some note abc')
    end

    expect(page).to have_css('.tasks-navigation', text: 'Ported Profile Org Z2')
  end

  it 'reflects the active state of members in their avatars' do
    visit "#organization/profile/#{organization.id}"

    within '.content.active .profile-window' do
      expect(page).to have_css('.userList-entry a.user-popover', text: member.fullname)
      expect(page).to have_css('.userList-entry .avatar--unique')
      expect(page).to have_no_css('.userList-entry .avatar--unique.avatar--inactive')
    end

    # Deactivate the member via its user profile.
    within '.content.active .profile-window' do
      click_on member.fullname
    end

    within(:active_content) do
      click '.js-action .icon-arrow-down'
      click '.js-action [data-type="edit"]'
    end

    in_modal do
      select 'inactive', from: 'active'

      click_on 'Submit'
    end

    # Back on the organization tab, the avatar shows the inactive state.
    find('.tasks-navigation .task', text: organization.name).click

    within '.content.active .profile-window' do
      expect(page).to have_css('.userList-entry .avatar--unique.avatar--inactive')
    end

    # Reactivating removes the inactive state again.
    within '.content.active .profile-window' do
      click_on member.fullname
    end

    within(:active_content) do
      click '.js-action .icon-arrow-down'
      click '.js-action [data-type="edit"]'
    end

    in_modal do
      select 'active', from: 'active'

      click_on 'Submit'
    end

    find('.tasks-navigation .task', text: organization.name).click

    within '.content.active .profile-window' do
      expect(page).to have_css('.userList-entry .avatar--unique')
      expect(page).to have_no_css('.userList-entry .avatar--unique.avatar--inactive')
    end
  end

  it 'syncs an inline note change into a second open session' do
    visit "#organization/profile/#{organization.id}"

    using_session(:second_browser) do
      login(username: create(:agent, password: 'test', groups: [group]).login, password: 'test')

      visit "#organization/profile/#{organization.id}"
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
