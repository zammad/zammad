# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Multitasking', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent)        { create(:agent, groups: [group]) }
  let(:group)        { create(:group) }
  let(:article)      { create(:ticket_article, :inbound_email, ticket: ticket) }
  let(:ticket)       { create(:ticket, group:, title: 'Test initial') }
  let(:other_ticket) { create(:ticket, group:, title: 'Other ticket') }
  let(:customer)     { create(:customer, :with_org) }

  before do
    10.times do |i|
      travel 1.day
      create(:ticket_article, ticket: ticket, body: "some message #{i}")
    end

    ticket.update! title: 'Changed title'

    10.times do
      travel 1.day
      create(:ticket_article, ticket: ticket)
    end
  end

  it 'history flyout stays around when switching between taskbars' do
    visit "/tickets/#{ticket.id}"

    wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")

    within('#ticketSidebar') do
      click_on 'Action menu button'
    end

    click_on 'History'

    wait_for_gql('apps/desktop/pages/ticket/graphql/queries/ticketHistory.graphql')

    scroll_into_view(find('#flyout-ticket-history'))

    flyout = find('#flyout-ticket-history')
    preserved_scroll_offset = flyout.find('.h-full').evaluate_script('this.scrollTop')

    click_on 'New ticket'
    find_input('Title').type('Example Ticket Title')
    find_autocomplete('Customer').search_for_option(customer.email, label: customer.fullname)
    text = find_editor('Text')
    text.type('some text')
    click_on 'Create'
    expect(page).to have_text('Ticket has been created successfully')

    click_on ticket.title

    expect(page).to have_css('#flyout-ticket-history')

    flyout = find('#flyout-ticket-history')
    current_scroll_offset = flyout.find('.h-full').evaluate_script('this.scrollTop')

    expect(preserved_scroll_offset).to eq(current_scroll_offset).and(be_positive)
  end

  it 'keeps new article form pinned and other ticket scrolling in place' do
    visit "/tickets/#{ticket.id}"
    visit "/tickets/#{other_ticket.id}"

    find('button', text: 'Add internal note').click
    within_form do
      find_editor('Text').type('Call content here')
    end
    click_on('Pin this panel')

    click_on(ticket.title)

    article = ticket.articles.third
    elem = find('.Content', text: article.body)
    scroll_into_view(elem)
    preserved_scroll_offset = find('div[data-test-id="ticket-detail-content-container"]').evaluate_script('this.scrollTop')

    click_on other_ticket.title

    expect(page).to have_text('Call content here')
    click_on('Unpin this panel')
    click_on('Update')

    expect(page).to have_text('Ticket updated successfully.')
    expect(page).to have_css('.Content', text: 'Call content here')

    click_on(ticket.title)

    current_scroll_offset = find('div[data-test-id="ticket-detail-content-container"]').evaluate_script('this.scrollTop')

    expect(preserved_scroll_offset).to eq(current_scroll_offset).and(be_positive)
  end
end
