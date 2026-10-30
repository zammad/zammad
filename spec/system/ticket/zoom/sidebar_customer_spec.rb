# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Sidebar > Customer', type: :system do
  context 'when using the sidebar' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), customer: create(:customer, :with_org)) }

    before do
      Setting.set("#{service_name}_integration", true) if defined? service_name
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does show the edit link for the customer' do
      click '.tabsSidebar-tab[data-tab=customer]'
      click '#userAction'
      click_on 'Edit Customer'
      modal_ready
    end

    it 'shows the password change hint when editing the customer' do
      click '.tabsSidebar-tab[data-tab=customer]'
      click '#userAction'
      click_on 'Edit Customer'

      in_modal do
        fill_in 'password', with: 'vXqXseF9L2ab'
        expect(page).to have_text('The user will be notified of the password change by email.')
      end
    end

    it 'does show the edit link for the organization' do
      click '.tabsSidebar-tab[data-tab=organization]'
      click '#userAction'
      click_on 'Edit Organization'
      modal_ready
    end

    %w[idoit gitlab github].each do |service_name|
      it "#{service_name} tab is hidden" do
        expect(page).to have_css('.tabsSidebar-tab[data-tab=customer]')
        expect(page).to have_no_css(".tabsSidebar-tab[data-tab=#{service_name}]")
      end

      context "when #{service_name} is enabled" do
        let(:service_name) { service_name }

        context 'when agent' do
          it "#{service_name} tab is visible" do
            expect(page).to have_css(".tabsSidebar-tab[data-tab=#{service_name}]")
          end
        end

        context 'when customer', authenticated_as: :customer do
          let(:customer) { ticket.customer }

          it "#{service_name} tab is hidden" do
            expect(page).to have_css('.ticketZoom-header .ticket-number', text: ticket.number)
            expect(page).to have_no_css(".tabsSidebar-tab[data-tab=#{service_name}]")
          end
        end
      end
    end
  end

  describe 'Sidebar - Open & Closed Tickets', performs_jobs: true, searchindex: true do
    let(:customer)      { create(:customer, :with_org) }
    let(:ticket_open)   { create(:ticket, group: Group.find_by(name: 'Users'), customer: customer, title: SecureRandom.uuid) }
    let(:ticket_closed) { create(:ticket, group: Group.find_by(name: 'Users'), customer: customer, state: Ticket::State.find_by(name: 'closed'), title: SecureRandom.uuid) }

    before do
      ticket_open
      ticket_closed
      perform_enqueued_jobs
      searchindex_model_reload([Ticket, User, Organization])
    end

    it 'does show open and closed tickets in advanced search url' do
      visit "#ticket/zoom/#{ticket_open.id}"
      click '.tabsSidebar-tab[data-tab=customer]'
      click '.user-tickets[data-type=open]'
      expect(page).to have_text(ticket_open.title)

      visit "#ticket/zoom/#{ticket_open.id}"
      click '.user-tickets[data-type=closed]'
      expect(page).to have_text(ticket_closed.title)
    end

    it 'keeps the ticket list closed when it loads after the pointer left' do
      response_gate = Queue.new
      request_entered = Queue.new

      allow_any_instance_of(TicketsController).to receive(:ticket_customer).and_wrap_original do |method, *args|
        request_entered << true
        response_gate.pop(timeout: 10)
        method.call(*args)
      end

      visit "#ticket/zoom/#{ticket_open.id}"
      click '.tabsSidebar-tab[data-tab=customer]'

      find('.user-tickets[data-type=open]') do |elem|
        elem.evaluate_script('Object.keys($(this).data()).includes("bs.popover")')
      end.hover

      expect(page).to have_css('.popover')
      request_entered.pop(timeout: 10)

      find('.menu').hover

      expect(page).to have_no_css('.popover')

      response_gate.close
      wait.until { page.evaluate_script('$.active').zero? }

      expect(page).to have_no_css('.popover', wait: 0)
    ensure
      response_gate&.close
    end
  end

  describe 'Sidebar - Organization' do
    let(:organization) { create(:organization) }

    describe 'members section' do

      let(:customers) { create_list(:customer, 50, organization: organization) }
      let(:ticket)    { create(:ticket, group: Group.find_by(name: 'Users'), customer: customers.first) }
      let(:members)   { organization.members.reorder(id: :asc) }

      before do
        visit "#ticket/zoom/#{ticket.id}"
        click '.tabsSidebar-tab[data-tab=organization]'
      end

      it 'shows first 10 members and loads more on demand' do
        expect(page).to have_text(members[9].fullname)
        expect(page).to have_no_text(members[10].fullname)

        click '.js-showMoreMembers'
        expect(page).to have_text(members[10].fullname)
      end
    end
  end

  describe 'Assign user to multiple organizations #1573', authenticated_as: :authenticate do
    let(:organizations) { create_list(:organization, 20) }
    let(:customer) { create(:customer, organization: organizations[0], organizations: organizations[1..]) }
    let(:ticket)   { create(:ticket, group: Group.first, customer: customer) }

    def authenticate
      customer
      true
    end

    before do
      visit "#ticket/zoom/#{ticket.id}"
      click '.tabsSidebar-tab[data-tab=customer]'
    end

    it 'shows only first 3 organizations and loads more on demand' do
      expect(page).to have_text(organizations[1].name)
      expect(page).to have_text(organizations[2].name)
      expect(page).to have_no_text(organizations[10].name)

      click '.js-showMoreOrganizations a'

      expect(page).to have_text(organizations[10].name)
    end
  end

  describe 'Open ticket indicator coloring setting' do
    let(:elem)     { find('[data-tab="customer"]') }
    let(:customer) { create(:customer) }
    let(:group)    { Group.first }
    let(:ticket)   { create(:ticket, customer: customer, group: group) }

    before do
      Setting.set 'ui_sidebar_open_ticket_indicator_colored', state

      customer.update! preferences: { tickets_open: tickets_count }

      visit "ticket/zoom/#{ticket.id}"
    end

    context 'when enabled' do
      let(:state) { true }

      context 'with 1 ticket' do
        let(:tickets_count) { 1 }

        it 'does not highlight' do
          expect(elem)
            .to have_no_css('.tabsSidebar-tab-count--danger, .tabsSidebar-tab-count--warning')
        end
      end

      context 'with 2 tickets' do
        let(:tickets_count) { 2 }

        it 'highlights as warning' do
          create(:ticket, customer: customer, group: group)

          expect(elem)
            .to have_no_css('.tabsSidebar-tab-count--danger')
            .and have_css('.tabsSidebar-tab-count--warning')
        end
      end

      context 'with 3 tickets' do
        let(:tickets_count) { 3 }

        it 'highlights as danger' do
          expect(elem)
            .to have_css('.tabsSidebar-tab-count--danger')
            .and have_no_css('.tabsSidebar-tab-count--warning')
        end
      end
    end

    context 'when disabled' do
      let(:state) { false }

      context 'with 2 tickets' do
        let(:tickets_count) { 2 }

        it 'does not highlight' do
          expect(elem)
            .to have_no_css('.tabsSidebar-tab-count--danger, .tabsSidebar-tab-count--warning')
        end
      end
    end
  end
end
