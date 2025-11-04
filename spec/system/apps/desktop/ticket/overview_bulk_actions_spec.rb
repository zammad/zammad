# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Overviews > Bulk Actions', app: :desktop_view, authenticated_as: :authenticate, type: :system do
  let(:dispatching_group) { create(:group, name: 'Dispatching') }
  let(:group1)            { create(:group, name: 'First level support') }
  let(:group2)            { create(:group, name: 'Technical assistance') }
  let(:dispatching_role)  { create(:role, name: 'Dispatcher') }
  let(:dispatcher)        { create(:agent, groups: [dispatching_group, group1, group2], roles: [Role.find_by(name: 'Agent'), dispatching_role]) }
  let(:agent1)            { create(:agent, groups: [group1]) }
  let(:agent2)            { create(:agent, groups: [group2]) }

  let(:dispatching_overview) do
    create(
      :overview,
      name:      'Tickets for Dispatching',
      prio:      9999,
      roles:     [dispatching_role],
      condition: {
        'ticket.group_id' => {
          operator: 'is',
          value:    dispatching_group.id,
        },
        'ticket.state_id' => {
          operator: 'is',
          value:    Ticket::State.find_by(name: 'new').id,
        },
      },
    )
  end

  let(:similar_tickets) do
    create_list(:ticket, 2, group: dispatching_group, title: 'Similar problem').tap do |tickets|
      tickets.each do |t|
        customer = create(:customer)
        UserInfo.current_user_id = customer.id
        create(:ticket_article, :inbound_email, ticket: t, from: customer.email, body: 'I have the same problem')
        t.update!(customer:)
      end
    end
  end

  let(:exploding_tickets) do
    create_list(:ticket, 3, group: dispatching_group, title: 'Exploding computer').tap do |tickets|
      tickets.each do |t|
        customer = create(:customer)
        UserInfo.current_user_id = customer.id
        create(:ticket_article, :inbound_email, ticket: t, from: customer.email, body: 'My computer just exploded 💥')
        t.update!(customer:)
      end
    end
  end

  let(:spam_tickets) do
    create_list(:ticket, 4, group: dispatching_group, title: '[SPAM] I am a ticket').tap do |tickets|
      tickets.each do |t|
        customer = create(:customer)
        UserInfo.current_user_id = customer.id
        create(:ticket_article, :inbound_email, ticket: t, from: customer.email, body: 'JK, I am spam')
        t.update!(customer:)
      end
    end
  end

  def authenticate
    dispatching_overview && agent1 && agent2 && similar_tickets && exploding_tickets && spam_tickets
    dispatcher
  end

  before do
    visit '/tickets/view/'
  end

  it 'can use custom overview and execute bulk actions on tickets' do
    within 'aside[aria-label="second level navigation sidebar"]' do
      click_on 'Tickets for Dispatching'
    end

    within 'main' do
      click_link similar_tickets.first.number
    end

    within 'main' do
      expect(page).to have_text('Similar problem')
        .and have_text('I have the same problem')
    end

    within 'aside[aria-label="Main sidebar"]' do
      find('li', text: 'Similar problem')
        .find('button[aria-label="Close this tab"]', visible: :all)
        .click
    end

    within 'main' do
      expect(page).to have_text('Tickets for Dispatching')

      similar_tickets.each do |ticket|
        find('td', text: ticket.number)
          .ancestor('tr')
          .find('[role="checkbox"]')
          .click
      end

      click_on 'Bulk Actions'
    end

    # NB: Due to dropdown menus being mounted to the end of the document body, we need the scope outside of the flyout
    #   container here.
    find_treeselect('Group').select_option('First level support')
    find_select('Owner').select_option(agent1.fullname)

    within 'aside[role="complementary"]' do
      find_toggle('Note').toggle_on
      find_editor('Text').type('Hey, can you please have a look? These tickets are similar to what we had yesterday already. Thanks!')

      click_on 'Apply'
    end

    expect(page).to have_text('The 2 selected tickets have been updated successfully.')

    within 'main' do
      expect(page).to have_no_text(similar_tickets.first.number)
        .and have_no_text(similar_tickets.second.number)

      exploding_tickets.each do |ticket|
        find('td', text: ticket.number)
          .ancestor('tr')
          .find('[role="checkbox"]')
          .click
      end

      click_on 'Bulk Actions'
    end

    # NB: Due to dropdown menus being mounted to the end of the document body, we need the scope outside of the flyout
    #   container here.
    find_treeselect('Group').select_option('Technical assistance')
    find_select('Priority').select_option('3 high')

    within 'aside[role="complementary"]' do
      find_toggle('Note').toggle_on
      find_editor('Text').type("We need your assessment. Is it really possible that the customer's computer exploded?")

      click_on 'Apply'
    end

    expect(page).to have_text('The 3 selected tickets have been updated successfully.')

    within 'main' do
      expect(page).to have_no_text(exploding_tickets.first.number)
        .and have_no_text(exploding_tickets.second.number)
        .and have_no_text(exploding_tickets.third.number)

      spam_tickets.each do |ticket|
        find('td', text: ticket.number)
          .ancestor('tr')
          .find('[role="checkbox"]')
          .click
      end

      click_on 'Bulk Actions'
    end

    within 'aside[role="complementary"]' do
      click 'button[aria-label="Context menu"]'
    end

    # NB: Due to popover menus being mounted to the end of the document body, we need the scope outside of the flyout
    #   container here.
    click_on 'Close & Tag as Spam'

    expect(page).to have_text('The 4 selected tickets have been updated successfully.')

    within 'main' do
      expect(page).to have_no_text(spam_tickets.first.number)
        .and have_no_text(spam_tickets.second.number)
        .and have_no_text(spam_tickets.third.number)
        .and have_no_text(spam_tickets.fourth.number)
        .and have_text('Empty Overview')
        .and have_text('No tickets in this state.')
    end
  end
end
