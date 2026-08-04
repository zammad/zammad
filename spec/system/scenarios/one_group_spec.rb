# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/abb_one_group_test.rb as a continuous end-to-end scenario:
#   as long as only a single group exists, the ticket create masks do not offer a group
#   selection; agents get invited via the first steps widget; once a second group is
#   created, the group selection appears.
RSpec.describe 'Scenario > From one group to multiple groups', authenticated_as: :authenticate, authentication_type: :form, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:admin)    { create(:admin, password: 'test', groups: [group]) }
  let(:customer) { create(:customer, password: 'test') }

  def authenticate
    # Establish the single-group state of the original test setup: the test database
    #   ships additional groups, which would make the group selection visible.
    Group.where.not(name: 'Users').find_each { |other_group| other_group.update!(active: false) }

    admin
  end

  it 'hides the group selection with a single group and reveals it with a second one' do
    # With a single group, the agent ticket create mask hides the group selection.
    visit '#ticket/create'

    within(:active_content) do
      expect(page).to have_css('.newTicket .form-group.hide [name="group_id"]', visible: :all)
    end

    # Invite an additional agent via the first steps widget.
    visit '#dashboard'

    within(:active_content) do
      click '.tab[data-area="first-steps-widgets"]'
      click '.js-inviteAgent'
    end

    in_modal do
      fill_in 'firstname', with: 'Bob'
      fill_in 'lastname',  with: 'Smith'
      fill_in 'email',     with: 'bob.smith.one.group@example.com'

      click 'span', text: 'Agent'

      within '.js-groupListNewItemRow' do
        click '.js-input'
        click 'li', text: group.name
        click 'input[value="full"]', visible: :all
        click '.js-add'
      end

      click('button')
    end

    expect(page).to have_no_text 'Sending'
    expect(User.find_by(email: 'bob.smith.one.group@example.com')).to have_attributes(firstname: 'Bob', lastname: 'Smith', group_ids: [group.id])

    # The customer ticket create mask hides the group selection as well.
    logout
    login(username: customer.email, password: 'test')

    visit '#customer_ticket_new'

    # Customers have no taskbar, therefore no `.content.active` scope exists here.
    within '.newTicket' do
      expect(page).to have_css('.form-group.hide input[name="group_id"]', visible: :all)

      find('[name="title"]').fill_in with: 'one group'
      find('[data-name="body"]').send_keys 'one group body'

      click '.js-submit'
    end

    expect(page).to have_css('.ticketZoom .js-objectTitle', text: 'one group')

    # After a second group exists, the agent ticket create mask offers the group selection.
    logout
    login(username: admin.email, password: 'test')

    visit '#manage/groups'

    within(:active_content) do
      click_on 'New Group'
    end

    in_modal do
      fill_in 'Name', with: 'Second group'

      click_on 'Submit'
    end

    expect(page).to have_css('table td', text: 'Second group')

    admin.groups << Group.find_by(name: 'Second group')

    page.refresh

    visit '#ticket/create'

    within(:active_content) do
      expect(page).to have_no_css('.newTicket .form-group.hide [name="group_id"]', visible: :all)
      expect(page).to have_css('.newTicket [name="group_id"]', visible: :all)
    end
  end
end
