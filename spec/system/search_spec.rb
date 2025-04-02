# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Search', authenticated_as: :authenticate, searchindex: true, type: :system do
  let(:group_1)               { create(:group) }
  let(:group_2)               { create(:group) }
  let(:macro_without_group)   { create(:macro) }
  let(:macro_group1)          { create(:macro, groups: [group_1]) }
  let(:macro_group2)          { create(:macro, groups: [group_2]) }
  let!(:ticket_1)             { create(:ticket, title: 'Testing Ticket 1', group: group_1) }
  let!(:ticket_2)             { create(:ticket, title: 'Testing Ticket 2', group: group_2) }
  let(:note)                  { 'Test note' }
  let(:authenticate_user)     { true }
  let(:before_authenticate)   { nil }

  def authenticate
    ticket_1 && ticket_2
    macro_without_group && macro_group1 && macro_group2
    before_authenticate
    searchindex_model_reload([Ticket, Organization, User])
    authenticate_user
  end

  before do
    visit '/'
  end

  it 'shows default widgets' do
    fill_in id: 'global-search', with: '"Welcome"'

    click_on 'Show Search Details'

    within '#navigation .tasks a[data-key=Search]' do
      expect(page).to have_content '"Welcome"'
    end
  end

  context 'with ticket search result' do
    let(:agent) { create(:agent, groups: Group.all) }
    let(:authenticate_user) { agent }

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

        expect(page).to have_css('.bulkAction.no-sidebar')
        expect(page).to have_no_selector('.bulkAction.no-sidebar.hide', visible: :all)
      end

      it 'shows bulkform when all checkbox is checked' do
        within '.detail-search table.table' do
          find('th.table-checkbox').check('bulk_all', allow_label_click: true)
        end

        expect(page).to have_css('.bulkAction.no-sidebar')
        expect(page).to have_no_selector('.bulkAction.no-sidebar.hide', visible: :all)
      end

      it 'hides bulkform when checkbox is unchecked' do
        within '.detail-search table.table' do
          find('th.table-checkbox').check('bulk_all', allow_label_click: true)

          all('.js-tableBody tr.item').each { |row| row.uncheck('bulk', allow_label_click: true) }
        end

        expect(page).to have_css('.bulkAction.no-sidebar.hide', visible: :hide)
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

    context 'with drag and drop' do
      context 'when checked tickets are dragged' do
        it 'shows the batch actions' do
          within(:active_content, '.main .table') do
            # get element to move
            element = page.find(:table_row, ticket_1.id).native
            click_and_hold(element)
            # move element a bit to display batch actions
            move_mouse_by(0, 5)
            # move mouse again to trigger the event for chrome
            move_mouse_by(0, 7)
          end

          expect(page).to have_css('.batch-overlay-circle--top.js-batch-macro-circle')
            .and(have_css('.batch-overlay-circle--bottom.js-batch-assign-circle'))
        end
      end
    end
  end

  context 'with ticket search result for macros bulk action' do
    let(:group_3)      { create(:group) }
    let(:search_query) { 'Testing' }
    let!(:ticket_3)    { create(:ticket, title: 'Testing Ticket 3', group: group_3) }
    let(:agent)        { create(:agent, groups: Group.all) }

    before do
      fill_in id: 'global-search', with: search_query
      click_on 'Show Search Details'

      find('[data-tab-content=Ticket]').click

      await_empty_ajax_queue
    end

    describe 'group-dependent macros' do
      let(:authenticate_user) { agent }
      let(:before_authenticate) { ticket_3 }

      it 'shows only non-group macro when ticket does not match any group macros' do
        within(:active_content) do
          display_macro_batches ticket_3

          expect(page).to have_selector(:macro_batch, macro_without_group.id)
            .and(have_no_selector(:macro_batch, macro_group1.id))
            .and(have_no_selector(:macro_batch, macro_group2.id))
        end
      end

      it 'shows non-group and matching group macros for matching ticket' do
        display_macro_batches ticket_1
        within(:active_content) do

          expect(page).to have_selector(:macro_batch, macro_without_group.id)
            .and(have_selector(:macro_batch, macro_group1.id))
            .and(have_no_selector(:macro_batch, macro_group2.id))
        end
      end
    end

    describe 'when agent cannot change some of the tickets' do
      let(:authenticate_user)   { agent }
      let(:before_authenticate) { agent.user_groups.create! group: ticket_3.group, access: 'read' }

      it 'show macros if agent cannot change selected tickets' do
        display_macro_batches ticket_1

        within(:active_content) do
          expect(page).to have_no_text(%r{No macros available}i)
            .and(have_selector(:macro_batch, macro_without_group.id))
        end
      end

      it 'show no macros if agent cannot change selected tickets' do
        display_macro_batches ticket_3

        within(:active_content) do
          expect(page).to have_text(%r{No macros available}i)
            .and(have_text(%r{no change permission}i))
            .and(have_no_selector(:macro_batch, macro_without_group.id))
        end
      end
    end

    describe 'when user is agent-customer' do
      let(:agent_customer) { create(:agent_and_customer) }
      let(:authenticate_user) { agent_customer }
      let(:before_authenticate) do
        ticket_1.update!(customer: agent_customer)
        agent_customer
          .tap { |user| user.groups << group_2 }
      end

      it 'show no macros if the ticket is customer-like' do
        display_macro_batches ticket_1

        within :active_content do
          expect(page).to have_text(%r{No macros available}i)
            .and(have_text(%r{no change permission}i))
            .and(have_no_selector(:macro_batch, macro_without_group.id))
            .and(have_no_selector(:macro_batch, macro_group1.id))
            .and(have_no_selector(:macro_batch, macro_group2.id))
        end
      end

      it 'show macros if tickets are only agent-like' do
        display_macro_batches ticket_2

        within :active_content do
          expect(page).to have_no_text(%r{No macros available}i)
            .and(have_selector(:macro_batch, macro_without_group.id))
            .and(have_no_selector(:macro_batch, macro_group1.id))
            .and(have_selector(:macro_batch, macro_group2.id))
        end
      end
    end

    describe 'when user is customer' do
      let(:customer) { create(:customer) }
      let(:authenticate_user)   { customer }
      let(:before_authenticate) { ticket_1.update!(customer: customer) }

      it 'shows no overlay' do
        display_macro_batches ticket_1

        within :active_content do
          expect(page).to have_no_selector('.batch-overlay-backdrop')
        end
      end
    end

    context 'with macro batch overlay' do
      shared_examples "adding 'small' class to macro element" do
        it 'adds a "small" class to the macro element' do
          display_macro_batches ticket_1
          within(:active_content) do

            expect(page).to have_css('.batch-overlay-macro-entry.small')
          end
        end
      end

      shared_examples "not adding 'small' class to macro element" do
        it 'does not add a "small" class to the macro element' do
          display_macro_batches ticket_1
          within(:active_content) do

            expect(page).to have_no_selector('.batch-overlay-macro-entry.small')
          end
        end
      end

      shared_examples 'showing all macros' do
        it 'shows all macros' do
          display_macro_batches ticket_1
          within(:active_content) do

            expect(page).to have_css('.batch-overlay-macro-entry', count: all)
          end
        end
      end

      shared_examples 'showing some macros' do |count|
        it 'shows all macros' do
          display_macro_batches ticket_1
          within(:active_content) do

            expect(page).to have_css('.batch-overlay-macro-entry', count: count)
          end
        end
      end

      let(:authenticate_user)   { agent }
      let(:before_authenticate) { Macro.destroy_all && create_list(:macro, all) }

      context 'with few macros' do
        let(:all) { 15 }

        context 'when on large screen', screen_size: :desktop do
          it_behaves_like 'showing all macros'
          it_behaves_like "not adding 'small' class to macro element"
        end

        context 'when on small screen', screen_size: :tablet do
          it_behaves_like 'showing all macros'
          it_behaves_like "not adding 'small' class to macro element"
        end

      end

      context 'with many macros' do
        let(:all) { 50 }

        context 'when on large screen', screen_size: :desktop do
          it_behaves_like 'showing some macros', 32
        end

        context 'when on small screen', screen_size: :tablet do
          it_behaves_like 'showing some macros', 24
          it_behaves_like "adding 'small' class to macro element"
        end
      end
    end
  end

  # https://github.com/zammad/zammad/issues/5505
  context 'when tickets are ordered by grroups' do
    let(:agent) { create(:agent, groups: Group.all) }
    let(:authenticate_user) { agent }

    let(:ticket_3) { create(:ticket, title: 'Testing Ticket 3', group: group_1) }
    let(:ticket_4) { create(:ticket, title: 'Testing Ticket 4', group: group_2) }
    let(:ticket_5) { create(:ticket, title: 'Testing Ticket 5', group: group_1) }
    let(:ticket_6) { create(:ticket, title: 'Testing Ticket 6', group: group_2) }

    before do
      ticket_4 && ticket_5 && ticket_6 && ticket_3

      searchindex_model_reload([Ticket, Organization, User])
      fill_in id: 'global-search', with: 'Testing'
      click_on 'Show Search Details'

      find('[data-tab-content=Ticket]').click
    end

    it 'sorts correctly' do
      # bug is most visible in descending order
      find('.table-column-title', text: 'GROUP').click
      find('.table-column-title', text: 'GROUP').click

      actual_ids   = all('.js-tableBody tr.item').map { |row| row['data-id'].to_i }
      expected_ids = [ticket_6, ticket_4, ticket_2, ticket_3, ticket_5, ticket_1].map(&:id)

      expect(actual_ids).to eq(expected_ids)
    end

  end

  context 'Organization members' do
    let(:organization) { create(:organization) }
    let(:members)      { organization.members.reorder(id: :asc) }

    let(:before_authenticate) { create_list(:customer, 50, organization: organization) }

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

      searchindex_model_reload([User, Organization])
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
    let(:agent)             { create(:agent, groups: Group.all) }
    let(:authenticate_user) { agent }

    context 'when search changed via input box' do
      before do
        visit '#search'
      end

      it 'does switch search results properly' do
        page.find('.js-search').fill_in(with: '"Testing Ticket 1"')
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

  context 'Assign user to multiple organizations #1573' do
    let(:organizations) { create_list(:organization, 20) }
    let(:customer)      { create(:customer, organization: organizations[0], organizations: organizations[1..]) }

    context 'when agent' do
      let(:authenticate_user) { true }
      let(:before_authenticate) { customer }

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

    context 'when customer' do
      let(:authenticate_user) { customer }

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

  describe 'Searches display all groups and owners on bulk selections #4054' do
    let(:group_1)   { create(:group) }
    let(:group_2)   { create(:group) }
    let(:agent_1)   { create(:agent, groups: [group_1]) }
    let(:agent_2)   { create(:agent, groups: [group_2]) }
    let(:agent_all) { create(:agent, groups: [group_1, group_2]) }
    let!(:ticket_1) { create(:ticket, group: group_1, title: '4054 group 1') }
    let!(:ticket_2) { create(:ticket, group: group_2, title: '4054 group 2') }

    let(:before_authenticate) { agent_1 && agent_2 && agent_all }
    let(:authenticate_user) { agent_all }

    def click_ticket(ticket)
      page.find(".js-tableBody tr.item[data-id='#{ticket.id}'] td.js-checkbox-field").click
    end

    def check_owner_agent1_shown
      expect(page).to have_select('owner_id', text: agent_1.fullname)
      expect(page).to have_no_select('owner_id', text: agent_2.fullname)
    end

    def check_owner_agent2_shown
      expect(page).to have_no_select('owner_id', text: agent_1.fullname)
      expect(page).to have_select('owner_id', text: agent_2.fullname)
    end

    def check_owner_field
      click_ticket(ticket_1)
      check_owner_agent1_shown
      click_ticket(ticket_1)
      click_ticket(ticket_2)
      check_owner_agent2_shown
    end

    context 'when search is used' do
      before do
        visit '#search/4054'
      end

      it 'does not show the bulk action when opening view' do
        expect(page).to have_text(ticket_1.title)
        expect(page).to have_text(ticket_2.title)
        expect(page).to have_no_css('.bulkAction select[name=owner_id]')
      end

      it 'does show the correct owner selection for each bulk action' do
        check_owner_field
      end
    end

    context 'when ticket overview is used' do
      before do
        visit '#ticket/view/all_unassigned'
      end

      it 'does not show the bulk action when opening view' do
        expect(page).to have_text(ticket_1.title)
        expect(page).to have_text(ticket_2.title)
        expect(page).to have_no_css('.bulkAction select[name=owner_id]')
      end

      it 'does show the correct owner selection for each bulk action' do
        check_owner_field
      end
    end
  end

  # https://github.com/zammad/zammad/issues/4264
  describe 'Keeps selected sorting' do
    before do
      fill_in id: 'global-search', with: 'Nico'

      click_on 'Show Search Details'

      find('.table-column-title', text: 'TITLE').click
    end

    it 'when switching to other taskbar keep sorting' do
      visit "ticket/zoom/#{Ticket.first.id}"

      click_on 'Nico'

      within('.table-column-head', text: 'TITLE') do
        expect(page).to have_css('.table-sort-arrow')
      end
    end

    it 'when switching to other search tab keep sorting' do
      within :active_content do
        find('.js-tab', text: 'User').click
        find('.js-tab', text: 'Ticket').click
      end

      # no need to wait for rerender in this case

      within('.table-column-head', text: 'TITLE') do
        expect(page).to have_css('.table-sort-arrow')
      end
    end

    it 'when changing search query clear sorting' do
      within :active_content do
        find('.js-search').fill_in with: 'Nicole'
      end

      within('.table-column-head', text: 'TITLE') do
        expect(page).to have_no_css('.table-sort-arrow')
      end
    end

    it 'when changing search query after navigation away-and-back clear sorting' do
      visit "ticket/zoom/#{Ticket.first.id}"

      click_on 'Nico'

      within :active_content do
        find('.js-search').fill_in with: 'Nicole'
      end

      within('.table-column-head', text: 'TITLE') do
        expect(page).to have_no_css('.table-sort-arrow')
      end
    end
  end

  describe 'Admin user can not find user or organization in the search bar #4574' do
    let(:admin) { create(:admin_only) }
    let(:agent)        { create(:agent, groups: [Group.first]) }
    let(:organization) { create(:organization, name: SecureRandom.uuid) }
    let(:customer)     { create(:customer, organization: organization, firstname: SecureRandom.uuid) }
    let(:ticket)       { create(:ticket, title: SecureRandom.uuid, customer: customer, group: Group.first) }

    before do
      visit '#dashboard'
    end

    context 'when customer' do
      let(:before_authenticate) { organization && customer && ticket }
      let(:authenticate_user) { customer }

      it 'does find the ticket' do
        fill_in id: 'global-search', with: ticket.title

        expect(page.find('.global-search-menu')).to have_content(ticket.title)
      end

      it 'does not find the customer' do
        fill_in id: 'global-search', with: customer.firstname

        expect(page.find('.global-search-menu')).to have_no_content(customer.firstname)
      end

      it 'does not find the organization' do
        fill_in id: 'global-search', with: organization.name

        expect(page.find('.global-search-menu')).to have_no_content(organization.name)
      end
    end

    context 'when agent' do
      let(:before_authenticate) { organization && customer && ticket }
      let(:authenticate_user) { agent }

      it 'does find the ticket' do
        fill_in id: 'global-search', with: ticket.title

        expect(page.find('.global-search-menu')).to have_content(ticket.title)
      end

      it 'does find the customer' do
        fill_in id: 'global-search', with: customer.firstname

        expect(page.find('.global-search-menu')).to have_content(customer.firstname)
      end

      it 'does find the organization' do
        fill_in id: 'global-search', with: organization.name

        expect(page.find('.global-search-menu')).to have_content(organization.name)
      end
    end

    context 'when admin only' do
      let(:authenticate_user) { admin }
      let(:before_authenticate) { organization && customer && ticket }

      it 'does not find the ticket' do
        fill_in id: 'global-search', with: ticket.title

        expect(page.find('.global-search-menu')).to have_no_content(ticket.title)
      end

      it 'does find the customer' do
        fill_in id: 'global-search', with: customer.firstname

        expect(page.find('.global-search-menu')).to have_content(customer.firstname)
      end

      it 'does find the organization' do
        fill_in id: 'global-search', with: organization.name

        expect(page.find('.global-search-menu')).to have_content(organization.name)
      end
    end
  end

  describe 'popover closes when item is opened' do
    let(:agent) { create(:agent, groups: Group.all) }
    let(:authenticate_user) { agent }

    before do
      fill_in id: 'global-search', with: 'Testing'
    end

    it 'closes popover when item is clicked' do
      elem = first('a.nav-tab.ticket-popover')
      popover_on_hover(elem)
      expect(page).to have_css('.popover')
      elem.click
      expect(page).to have_no_css('.popover')
    end

    it 'closes popover when item is opened via keyboard' do
      first('a.nav-tab.ticket-popover') # ensure search results are visible
      send_keys(:down) # go to detailed search
      send_keys(:down) # go to first ticket
      expect(page).to have_css('.popover')
      send_keys(:enter) # open
      expect(page).to have_no_css('.popover')
    end
  end

  describe 'search with many results', searchindex: false do
    let(:new_customers) { create_list(:customer, 55) }
    let(:all_zammad_customers)        { User.where('email LIKE ?', '%zammad%') }
    let(:all_zammad_customers_sorted) { all_zammad_customers.reorder(:login) }

    context 'with many customers' do
      before do
        new_customers
        visit '#search/zammad'
      end

      it 'shows 50 on first page and remaining on second page' do
        expect(page).to have_css('.tab[data-tab-content=User] .tab-badge', text: all_zammad_customers.count)

        click '.tab[data-tab-content=User]'

        expect(page).to have_css('.js-tableBody tr', count: 50)

        page.first('.js-page', text: '2').click

        expect(page).to have_css('.js-tableBody tr', count: all_zammad_customers.count % 50)
      end

      it 'sorts correctly across pages' do
        click '.tab[data-tab-content=User]'

        first('.js-sort').click

        expect(page).to have_css('.js-tableBody tr:first-child',
                                 text: all_zammad_customers_sorted.first.login)

        first('.js-sort').click

        expect(page).to have_css('.js-tableBody tr:first-child',
                                 text: all_zammad_customers_sorted.last.login)

        first('.js-page', text: '2').click

        expect(page).to have_css('.js-tableBody tr:last-child',
                                 text: all_zammad_customers_sorted.first.login)
      end
    end

    context 'when many tickets exist too' do
      let(:new_tickets) do
        Array.new(55).map.with_index do |_elem, i|
          t = create(:ticket, group: Ticket.find(1).group, title: "Ticket #{i} zammad")
          create(:ticket_article, ticket: t)
        end
      end

      let(:all_zammad_tickets)         { Ticket.where('title LIKE ?', '%ammad%') }
      let(:all_zammad_tickets_default) { all_zammad_tickets.reorder('updated_at desc').to_a }
      let(:all_zammad_tickets_sorted)  { all_zammad_tickets.reorder(:title).to_a }

      before do
        new_tickets
        visit '#search/ammad'
      end

      it 'keeps pagination and sorting when switching taskbars' do
        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_default.first.title)

        all('.js-sort')[2].click

        expect(page).to have_css('.table-sort-arrow')

        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_sorted.first.title)

        first('.js-page', text: '2').click

        expect(page).to have_css('.js-tableBody tr:last-child', text: all_zammad_tickets_sorted.last.title)
        expect(page).to have_css('.js-page.btn--active', text: 2)

        click_on('Dashboard')

        all_zammad_tickets_sorted.last.destroy!
        browser_travel_to 1.hour.from_now

        find('a[href="#search"]').click

        expect(page).to have_css('.table-sort-arrow')
        expect(page).to have_css('.js-page.btn--active', text: 2)
        expect(page).to have_css('.js-tableBody tr:last-child', text: all_zammad_tickets_sorted.second_to_last.title)
      end

      it 'keeps background tab pagination and sorting when switching taskbars' do
        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_default.first.title)

        all('.js-sort')[2].click
        expect(page).to have_css('.table-sort-arrow')
        first('.js-page', text: '2').click
        expect(page).to have_css('.js-page.btn--active', text: 2)
        expect(page).to have_css('.js-tableBody tr:last-child', text: all_zammad_tickets_sorted.last.title)

        click '.tab[data-tab-content=User]'

        click_on('Dashboard')

        all_zammad_tickets_sorted.last.destroy!
        browser_travel_to 1.hour.from_now

        find('a[href="#search"]').click

        click '.tab[data-tab-content=Ticket]'

        expect(page).to have_css('.table-sort-arrow')
        expect(page).to have_css('.js-page.btn--active', text: 2)
        expect(page).to have_css('.js-tableBody tr:last-child', text: all_zammad_tickets_sorted.second_to_last.title)
      end

      it 'updates tab without sorting or pagination' do
        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_default.first.title)

        click_on('Dashboard')

        all_zammad_tickets_default.first.destroy!
        browser_travel_to 1.hour.from_now

        find('a[href="#search"]').click

        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_default.second.title)
      end

      it 'updates background tab without sorting or pagination' do
        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_default.first.title)

        click '.tab[data-tab-content=User]'

        click_on('Dashboard')

        all_zammad_tickets_default.first.destroy!
        browser_travel_to 1.hour.from_now

        find('a[href="#search"]').click

        click '.tab[data-tab-content=Ticket]'

        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_default.second.title)
      end

      it 'keeps pagination and sorting when switching taskbars and there is no enough content anymore' do
        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_default.first.title)

        all('.js-sort')[2].click

        expect(page).to have_css('.table-sort-arrow')

        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_sorted.first.title)

        first('.js-page', text: '2').click

        expect(page).to have_css('.js-tableBody tr:last-child', text: all_zammad_tickets_sorted.last.title)
        expect(page).to have_css('.js-page.btn--active', text: 2)

        click_on('Dashboard')

        all_zammad_tickets_sorted.last(10).each(&:destroy!)
        browser_travel_to 1.hour.from_now

        find('a[href="#search"]').click

        expect(page).to have_no_css('.table-sort-arrow')
        expect(page).to have_no_css('.js-page.btn--active', text: 2)
        expect(page).to have_no_css('.js-page.btn--active', text: 1)
        expect(page).to have_css('.js-page.btn', text: 1)

        first('.js-page', text: '1').click
        expect(page).to have_css('.table-sort-arrow')
        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_sorted.first.title)
      end

      it 'keeps pagination and sorting after bulk form update' do
        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_default.first.title)

        all('.js-sort')[2].click

        expect(page).to have_css('.table-sort-arrow')

        expect(page).to have_css('.js-tableBody tr:first-child', text: all_zammad_tickets_sorted.first.title)

        first('.js-page', text: '2').click

        find('.js-tableBody tr:last-child td.table-checkbox').check('bulk', allow_label_click: true)

        find('select[name=owner_id]').find('option:nth-child(2)').select_option
        click '.js-confirm'
        click '.js-submit'

        expect(page).to have_text('Bulk action executed!')

        expect(page).to have_css('.table-sort-arrow')
        expect(page).to have_css('.js-page.btn--active', text: 2)
        expect(page).to have_css('.js-tableBody tr:last-child', text: all_zammad_tickets_sorted.last.title)
      end
    end
  end
end
