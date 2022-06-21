# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Search', type: :system, authenticated: true, searchindex: true do
  let(:users_group) { Group.find_by(name: 'Users') }
  let(:ticket_1)    { create(:ticket, title: 'Testing Ticket 1', group: users_group) }
  let(:ticket_2)    { create(:ticket, title: 'Testing Ticket 2', group: users_group) }
  let(:note)        { 'Test note' }

  before do
    ticket_1 && ticket_2 && configure_elasticsearch(required: true, rebuild: true)
  end

  it 'shows default widgets' do
    fill_in id: 'global-search', with: '"Welcome"'

    click_on 'Show Search Details'

    within '#navigation .tasks a[data-key=Search]' do
      expect(page).to have_content '"Welcome"'
    end
  end

  context 'with ticket search result' do
    before do
      fill_in id: 'global-search', with: 'Testing'
      click_on 'Show Search Details'

      find('[data-tab-content=Ticket]').click
    end

    context 'checkbox' do
      it 'has checkbox for each ticket records' do
        within '.detail-search table.table' do
          expect(page).to have_xpath(".//td[contains(@class, 'js-checkbox-field')]//input[@type='checkbox']", visible: :all, minimum: 2)
        end
      end

      it 'has select all checkbox' do
        within '.detail-search table.table' do
          expect(page).to have_xpath(".//th//input[@type='checkbox' and @name='bulk_all']", visible: :all, count: 1)
        end
      end

      it 'shows bulkform when checkbox is checked' do
        within '.detail-search table.table' do
          find("tr[data-id='#{ticket_1.id}']").check('bulk', allow_label_click: true)
        end

        expect(page).to have_selector('.bulkAction.no-sidebar')
        expect(page).to have_no_selector('.bulkAction.no-sidebar.hide', visible: :all)
      end

      it 'shows bulkform when all checkbox is checked' do
        within '.detail-search table.table' do
          find('th.table-checkbox').check('bulk_all', allow_label_click: true)
        end

        expect(page).to have_selector('.bulkAction.no-sidebar')
        expect(page).to have_no_selector('.bulkAction.no-sidebar.hide', visible: :all)
      end

      it 'hides bulkform when checkbox is unchecked' do
        within '.detail-search table.table' do
          find('th.table-checkbox').check('bulk_all', allow_label_click: true)

          all('.js-tableBody tr.item').each { |row| row.uncheck('bulk', allow_label_click: true) }
        end

        expect(page).to have_selector('.bulkAction.no-sidebar.hide', visible: :hide)
      end
    end

    context 'with bulkform activated' do
      before do
        find('th.table-checkbox').check('bulk_all', allow_label_click: true)
      end

      it 'has group label' do
        within '.bulkAction .bulkAction-form' do
          expect(page).to have_content 'GROUP'
        end
      end

      it 'has owner label' do
        within '.bulkAction .bulkAction-form' do
          expect(page).to have_content 'OWNER'
        end
      end

      it 'has state label' do
        within '.bulkAction .bulkAction-form' do
          expect(page).to have_content 'STATE'
        end
      end

      it 'has priority label' do
        within '.bulkAction .bulkAction-form' do
          expect(page).to have_content 'PRIORITY'
        end
      end
    end

    context 'bulk note' do
      it 'adds note to selected ticket' do
        within :active_content do
          find("tr[data-id='#{ticket_1.id}']").check('bulk', allow_label_click: true)
          click '.js-confirm'
          find('.js-confirm-step textarea').fill_in with: note
          click '.js-submit'
        end

        expect do
          wait.until { ticket_1.articles.last&.body == note }
        end.not_to raise_error
      end
    end
  end

  context 'Organization members', authenticated_as: :authenticate do
    let(:organization) { create(:organization) }
    let(:members) { organization.members.order(id: :asc) }

    def authenticate
      create_list(:customer, 50, organization: organization)
      true
    end

    before do
      fill_in id: 'global-search', with: organization.name.to_s
    end

    it 'shows only first 10 members' do
      expect(page).to have_text(organization.name)
      popover_on_hover(first('a.nav-tab.organization'))
      expect(page).to have_text(members[9].fullname, wait: 30)
      expect(page).to have_no_text(members[10].fullname)
    end
  end

  context 'inactive user and organizations' do
    before do
      create(:organization, name: 'Example Inc.', active: true)
      create(:organization, name: 'Example Inactive Inc.', active: false)
      create(:customer, firstname: 'Firstname', lastname: 'Active', active: true)
      create(:customer, firstname: 'Firstname', lastname: 'Inactive', active: false)

      configure_elasticsearch(rebuild: true)
    end

    it 'check that inactive organizations are marked correctly' do
      fill_in id: 'global-search', with: '"Example"'

      expect(page).to have_css('.nav-tab--search.organization', minimum: 2)
      expect(page).to have_css('.nav-tab--search.organization.is-inactive', count: 1)
    end

    it 'check that inactive users are marked correctly' do
      fill_in id: 'global-search', with: '"Firstname"'

      expect(page).to have_css('.nav-tab--search.user', minimum: 2)
      expect(page).to have_css('.nav-tab--search.user.is-inactive', count: 1)
    end

    it 'check that inactive users are also marked in the popover for the quick search result' do
      fill_in id: 'global-search', with: '"Firstname"'

      popover_on_hover(find('.nav-tab--search.user.is-inactive'))

      expect(page).to have_css('.popover-title .is-inactive', count: 1)
    end
  end

  describe 'Search is not triggered/updated if url of search is updated new search item or new search is triggered via global search #3873' do

    context 'when search changed via input box' do
      before do
        visit '#search'
      end

      it 'does switch search results properly' do
        page.find('.js-search').fill_in(with: '"Testing Ticket 1"', fill_options: { clear: :backspace })
        expect(page.find('.js-tableBody')).to have_text('Testing Ticket 1')
        expect(page.find('.js-tableBody')).to have_no_text('Testing Ticket 2')
        expect(current_url).to include('Testing%20Ticket%201')

        # switch by global search
        page.find('.js-search').fill_in(with: '"Testing Ticket 2"', fill_options: { clear: :backspace })
        expect(page.find('.js-tableBody')).to have_text('Testing Ticket 2')
        expect(page.find('.js-tableBody')).to have_no_text('Testing Ticket 1')
        expect(current_url).to include('Testing%20Ticket%202')
      end
    end

    context 'when search changed via global search' do
      before do
        fill_in id: 'global-search', with: '"Testing Ticket 1"'
        click_on 'Show Search Details'
      end

      it 'does switch search results properly' do
        expect(page.find('.js-tableBody')).to have_text('Testing Ticket 1')
        expect(page.find('.js-tableBody')).to have_no_text('Testing Ticket 2')
        expect(current_url).to include('Testing%20Ticket%201')

        # switch by global search
        fill_in id: 'global-search', with: '"Testing Ticket 2"'
        click_on 'Show Search Details'
        expect(page.find('.js-tableBody')).to have_text('Testing Ticket 2')
        expect(page.find('.js-tableBody')).to have_no_text('Testing Ticket 1')
        expect(current_url).to include('Testing%20Ticket%202')
      end
    end

    context 'when search is changed via url' do
      before do
        visit '#search/"Testing Ticket 1"'
      end

      it 'does switch search results properly' do
        expect(page.find('.js-tableBody')).to have_text('Testing Ticket 1')
        expect(page.find('.js-tableBody')).to have_no_text('Testing Ticket 2')
        expect(current_url).to include('Testing%20Ticket%201')

        # switch by url
        visit '#search/"Testing Ticket 2"'
        expect(page.find('.js-tableBody')).to have_text('Testing Ticket 2')
        expect(page.find('.js-tableBody')).to have_no_text('Testing Ticket 1')
        expect(current_url).to include('Testing%20Ticket%202')
      end
    end
  end

  context 'Assign user to multiple organizations #1573', authenticated_as: :authenticate do
    let(:organizations) { create_list(:organization, 20) }
    let(:customer) { create(:customer, organization: organizations[0], organizations: organizations[1..]) }

    context 'when agent' do
      def authenticate
        customer
        true
      end

      before do
        fill_in id: 'global-search', with: customer.firstname.to_s
      end

      it 'shows only first 3 organizations' do
        expect(page).to have_text(customer.firstname)
        popover_on_hover(first('a.nav-tab.user'))
        within '.popover' do
          expect(page).to have_text(organizations[2].name, wait: 30)
          expect(page).to have_no_text(organizations[10].name)
        end
      end
    end

    context 'when customer', authenticated_as: :customer do
      before do
        fill_in id: 'global-search', with: organizations[0].name.to_s
      end

      it 'does not show any organizations in global search because only agents have access to it' do
        within '.global-search-result' do
          expect(page).to have_no_text(organizations[0].name)
        end
      end
    end
  end

  describe 'Searches display all groups and owners on bulk selections #4054', authenticated_as: :authenticate do
    let(:group1) { create(:group) }
    let(:group2)    { create(:group) }
    let(:agent1)    { create(:agent, groups: [group1]) }
    let(:agent2)    { create(:agent, groups: [group2]) }
    let(:agent_all) { create(:agent, groups: [group1, group2]) }
    let(:ticket1)   { create(:ticket, group: group1, title: '4054 group 1') }
    let(:ticket2)   { create(:ticket, group: group2, title: '4054 group 2') }

    def authenticate
      agent1 && agent2 && agent_all
      ticket1 && ticket2
      agent_all
    end

    def check_owner_empty
      expect(page).to have_select('owner_id', text: '-', visible: :all)
      expect(page).to have_no_select('owner_id', text: agent1.fullname, visible: :all)
      expect(page).to have_no_select('owner_id', text: agent2.fullname, visible: :all)
    end

    def click_ticket(ticket)
      page.find(".js-tableBody tr.item[data-id='#{ticket.id}'] td.js-checkbox-field").click
    end

    def check_owner_agent1_shown
      expect(page).to have_select('owner_id', text: agent1.fullname)
      expect(page).to have_no_select('owner_id', text: agent2.fullname)
    end

    def check_owner_agent2_shown
      expect(page).to have_no_select('owner_id', text: agent1.fullname)
      expect(page).to have_select('owner_id', text: agent2.fullname)
    end

    def check_owner_field
      check_owner_empty
      click_ticket(ticket1)
      check_owner_agent1_shown
      click_ticket(ticket1)
      click_ticket(ticket2)
      check_owner_agent2_shown
    end

    context 'when search is used' do
      before do
        visit '#search/4054'
      end

      it 'does show the correct owner selection for each bulk action' do
        check_owner_field
      end
    end

    context 'when ticket overview is used' do
      before do
        visit '#ticket/view/all_unassigned'
      end

      it 'does show the correct owner selection for each bulk action' do
        check_owner_field
      end
    end
  end
end
