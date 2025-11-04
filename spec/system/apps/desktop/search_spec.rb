# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Search', app: :desktop_view, authenticated_as: :authenticate, searchindex: true, type: :system do
  let(:group)                { create(:group) }
  let(:agent)                { create(:agent, groups: [group]) }
  let(:customer)             { create(:customer, :with_org) }
  let(:old_ticket)           { create(:ticket, title: 'Old Ticket Title', group:, customer:, state: Ticket::State.find_by(name: 'closed')) }
  let(:question)             { Faker::Lorem.unique.question }
  let(:old_customer_article) { create(:ticket_article, :inbound_email, ticket: old_ticket, from: customer.email, body: question) }
  let(:answer)               { Faker::Lorem.unique.paragraph(sentence_count: 3) }
  let(:old_agent_article)    { create(:ticket_article, :outbound_email, ticket: old_ticket, from: agent.email, body: answer) }
  let(:new_ticket)           { create(:ticket, title: 'New Ticket Title', group:, customer:) }
  let(:new_customer_article) { create(:ticket_article, :inbound_email, ticket: new_ticket, from: customer.email, body: question) }

  def authenticate
    travel_to 6.months.ago
    UserInfo.current_user_id = customer.id
    old_customer_article
    UserInfo.current_user_id = agent.id
    old_agent_article
    travel_back
    UserInfo.current_user_id = customer.id
    new_customer_article
    searchindex_model_reload([Ticket, Organization, User])
    agent
  end

  before do
    visit "/tickets/#{new_ticket.id}"
  end

  it 'can search for related issues to answer customer ticket' do
    within 'main' do
      expect(page).to have_text(customer.fullname)
        .and have_text(new_customer_article.body)
    end

    within 'aside[aria-label="Main sidebar"]' do
      find('[role="searchbox"][aria-label="Search…"').fill_in with: customer.fullname

      expect(page).to have_text('Found users')
        .and have_link(customer.fullname)

      click_on 'detailed search'
    end

    wait.until { current_url.include?("search/#{CGI.escapeURIComponent(customer.fullname)}") }

    within 'main' do
      find('[role="tab"]', text: 'User').click

      expect(page).to have_link(customer.login)

      find('[role="tab"]', text: 'Ticket').click
      find('[role="searchbox"][aria-label="Search…"').fill_in with: 'foobar'

      expect(page).to have_text('No search results for this query.')

      click_on 'Clear search'

      expect(page).to have_text('Start typing to get the search results.')

      find('[role="searchbox"][aria-label="Search…"').fill_in with: "state.name: closed AND article.from: #{agent.fullname} AND customer.firstname: #{customer.firstname}"

      click_on old_ticket.number
    end

    wait.until { current_url.end_with?("tickets/#{old_ticket.id}") }

    within 'main' do
      expect(page).to have_text(agent.fullname)
        .and have_text(answer)
    end

    within '#user-taskbar-tabs' do
      click_on 'New Ticket Title'
    end

    within 'main' do
      click_on 'Add reply'
      find_editor('Text').type(answer)

      wait_for_form_updater
    end

    within 'footer' do
      click_on 'Update'

      wait_for_gql('shared/entities/ticket/graphql/mutations/update.graphql')
    end

    expect(new_ticket.reload.articles.last.body).to include(answer)
  end
end
