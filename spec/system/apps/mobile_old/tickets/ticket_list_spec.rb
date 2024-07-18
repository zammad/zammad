# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Mobile > Tickets', app: :mobile, authenticated_as: :agent, type: :system do
  let(:organization)     { create(:organization) }
  let(:user)             { create(:user, organization: organization) }
  let(:group)            { create(:group) }
  let(:agent)            { create(:agent) }
  let(:open_tickets)     { create_list(:ticket, 20, title: 'Test Ticket', customer: user, organization: organization, group: group, created_by_id: user.id, state: Ticket::State.lookup(name: 'open')) }
  let(:overview_tickets) { Ticket::Overviews.tickets_for_overview(Overview.find_by(link: 'all_open'), agent).limit(nil) }

  before do
    Overview.find_by(link: 'all_open').update!(
      view: {
        s:                 %w[number title customer group state owner created_at],
        view_mode_default: 's',
      },
    )

    open_tickets
    overview_tickets

    agent.group_names_access_map = Group.all.to_h { |g| [g.name, ['full']] }

    visit route
  end

  def wait_for_tickets(count:)
    expect(page).to have_css('a[href^="/mobile/tickets/"]:not([href$="/create"])', count: count)
  end

  context 'when on "Open Tickets" view' do
    let(:route) { '/tickets/view/all_open' }

    it 'keeps the scroll position when going back' do
      wait_for_tickets(count: 10)

      page.scroll_to :bottom

      wait_for_tickets(count: 20)

      link = find_link(href: "/mobile/tickets/#{open_tickets[6].id}")
      position_old = link.evaluate_script('this.getBoundingClientRect().top')

      link.find('span', text: 'Test Ticket').click

      wait_for_gql('apps/mobile/entities/ticket/graphql/queries/ticketWithMentionLimit.graphql')

      find_button('Go back').click

      wait_for_gql('shared/entities/ticket/graphql/queries/ticket/overviews.graphql')

      expect_current_route '/tickets/view/all_open'

      wait.until do
        position_new = find_link(href: "/mobile/tickets/#{open_tickets[6].id}").evaluate_script('this.getBoundingClientRect().top')
        position_new == position_old
      end
    end

    it 'opens the sort dialog and reorders the list' do
      find('[data-test-id="column"]').click

      expect(page.find('[role="dialog"]')).to have_text('Number')
      expect(page.find('[role="dialog"]')).to have_text('descending')

      find('span', text: 'Number').click
      find('button', text: 'descending').click

      send_keys(:escape)

      expect(page).to have_no_css('[role="dialog"]')

      within('section') do
        expect(find('a[href^="/mobile/tickets/"]:first-of-type')).to have_text(open_tickets.last.number)
      end
    end
  end

  context 'when on "Home" screen' do
    let(:route) { '/' }

    it 'can change the selected ticket overview' do
      find_link('Open Tickets', href: '/mobile/tickets/view/all_open').click

      wait.until do
        expect(page).to have_text("Open Tickets\n(21)")
      end

      find('button', text: "Open Tickets\n(21)").click

      expect(page.find('[role="dialog"]')).to have_text('Escalated Tickets')

      find('span', text: 'Escalated Tickets').click

      expect(page).to have_no_css('[role="dialog"]')
        .and have_text("Escalated Tickets\n(0)")
    end
  end
end
