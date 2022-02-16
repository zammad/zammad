# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'First Steps', type: :system do

  let(:agent) { "bob.smith_#{SecureRandom.uuid}" }
  let(:customer) { "customer.smith_#{SecureRandom.uuid}" }

  before do
    visit 'dashboard'

    within :active_content do
      click '.tab[data-area="first-steps-widgets"]'
    end
  end

  it 'show first steps configuration page' do
    within :active_content do
      expect(page).to have_text 'Configuration'
    end
  end

  it 'invites agent (with more then one group)' do
    within(:active_content) { click '.js-inviteAgent' }

    target_group = Group.last

    in_modal do
      fill_in 'firstname', with: 'Bob'
      fill_in 'lastname',  with: 'Smith'
      fill_in 'email',     with: "#{agent}@example.com"

      check "group_ids::#{target_group.id}", option: 'full', allow_label_click: true
      click('button')
    end

    wait.until { expect(User.last).to have_attributes(firstname: 'Bob', lastname: 'Smith', group_ids: [target_group.id]) }
    expect(page).to have_no_text 'Sending'
  end

  it 'invites customer' do
    within(:active_content) { click '.js-inviteCustomer' }

    in_modal do
      fill_in 'firstname', with: 'Client'
      fill_in 'lastname',  with: 'Smith'
      fill_in 'email',     with: "#{customer}@example.com"

      click('button')
    end

    wait.until { expect(User.last).to have_attributes(firstname: 'Client', lastname: 'Smith') }
    expect(page).to have_no_text 'Sending'
  end

  it 'creates test ticket', sessions_jobs: true do
    # make window large enough to show activity stream
    page.current_window.resize_to(1520, 800)

    initial_ticket_count = Ticket.count

    within(:active_content) { click '.js-testTicket' }

    within '.sidebar .js-activityContent' do
      wait.until { Ticket.count == (initial_ticket_count + 1) }
      expect(page).to have_text 'Nicole Braun created article for Test Ticket!'
    end
  end

  it 'updates online form channel' do
    Setting.set('form_ticket_create', true)

    page.refresh

    within :active_content do
      click '.tab[data-area="first-steps-widgets"]'
    end

    expect(page).to have_selector 'a[href="#channels/form"].todo.is-done'
  end
end
