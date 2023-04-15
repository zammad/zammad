# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
  end

  def wait_for_tickets(count:)
    wait.until do
      expect(page).to have_css('a[href^="/mobile/tickets/"]:not([href$="/create"])', count: count)
    end
  end

  context 'when on "Open Tickets" view' do
    before do
      visit '/tickets/view/all_open'
    end

    context 'when going between list and ticket' do
      it 'going back keeps the scroll position' do
        wait_for_tickets(count: 10)

        page.scroll_to :bottom

        wait_for_tickets(count: 20)

        link = find_link(href: "/mobile/tickets/#{open_tickets[6].id}")
        position_old = link.evaluate_script('this.getBoundingClientRect().top')

        link.find('span', text: 'Test Ticket').click

        find_button('Go back').click

        expect_current_route '/tickets/view/all_open'

        position_new = find_link(href: "/mobile/tickets/#{open_tickets[6].id}").evaluate_script('this.getBoundingClientRect().top')
        expect(position_old).to eq(position_new)
      end
    end

    context 'when changing sort by and order by' do
      it 'opens the dialog and reorders the list' do
        find('[data-test-id="column"]').click

        expect(page.find('[role="dialog"]')).to have_text('Number')
        expect(page.find('[role="dialog"]')).to have_text('descending')

        find('span', text: 'Number').click
        find('button', text: 'descending').click

        send_keys(:escape)

        wait.until do
          expect(page).to have_no_css('[role="dialog"]')
        end

        within('section') do
          expect(find('a[href^="/mobile/tickets/"]:first-of-type')).to have_text(open_tickets.last.number)
        end
      end
    end

    context 'when changing the selected ticket overview' do
      before do
        visit '/'
      end

      it 'could change the overview' do
        find_link('Open Tickets', href: '/mobile/tickets/view/all_open').click

        wait.until do
          expect(page).to have_text("Open Tickets\n(21)")
        end

        find('button', text: "Open Tickets\n(21)").click

        expect(page.find('[role="dialog"]')).to have_text('Escalated Tickets')

        find('span', text: 'Escalated Tickets').click

        wait.until do
          expect(page).to have_no_css('[role="dialog"]')
          expect(page).to have_text("Escalated Tickets\n(0)")
        end
      end
    end
  end
end
