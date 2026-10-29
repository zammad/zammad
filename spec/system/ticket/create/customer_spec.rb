# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Create > Customer', time_zone: 'Europe/London', type: :system do
  describe 'customer selection to check the field search' do
    before do
      create(:customer, active: true)
      create(:customer, active: false)
    end

    it 'check for inactive customer in customer/organization selection' do
      visit 'ticket/create'

      within(:active_content) do
        find('[name=customer_id] ~ .user-select.token-input').fill_in with: '**'
        expect(page).to have_css('ul.recipientList > li.recipientList-entry', minimum: 2)
        expect(page).to have_css('ul.recipientList > li.recipientList-entry.is-inactive', count: 1)
      end
    end
  end

  context 'when agent and customer user login after another' do
    let(:agent)    { create(:agent, password: 'test') }
    let(:customer) { create(:customer, password: 'test') }

    it 'customer user should not have agent object attributes', authenticated_as: false do

      # Create agent session and fetch object attributes.
      login(
        username: agent.login,
        password: 'test'
      )
      visit 'ticket/create'

      expect(page).to have_field('customer_id', type: 'hidden')

      # Remove local object attributes bound to the session.
      #   There was an issue (#1856) where the old attribute values
      #   persisted and were stored as the original attributes.
      logout

      # Create customer session and fetch object attributes.
      login(
        username: customer.login,
        password: 'test'
      )
      visit 'customer_ticket_new'

      expect(page).to have_field('title')
      expect(page).to have_no_field('customer_id', type: 'hidden')
    end
  end

  describe 'When looking for customers, it is no longer possible to change into organizations #3815' do
    before do
      visit 'ticket/create'

      find('[name=customer_id_completion]')
      wait.until_disappears { find('.modal', wait: 0) }
    end

    context 'when less than 10 customers' do
      let(:organization) { Organization.first }

      it 'has no show more option' do
        find('[name=customer_id_completion]').fill_in with: 'zam'
        expect(page).to have_css("li.js-organization[data-organization-id='#{organization.id}']")
        page.find("li.js-organization[data-organization-id='#{organization.id}']").click
        expect(page).to have_css("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers.hidden", visible: :all)
      end
    end

    context 'when more than 10 customers', authenticated_as: :authenticate do
      def authenticate
        customers
        true
      end

      let(:organization) { create(:organization, name: 'Zammed') }
      let(:customers) do
        create_list(:customer, 26, organization: organization)
      end

      it 'does paginate through organization' do
        find('[name=customer_id_completion]').fill_in with: 'zam'
        expect(page).to have_css("li.js-organization[data-organization-id='#{organization.id}']")
        page.find("li.js-organization[data-organization-id='#{organization.id}']").click
        wait.until { page.all("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li", visible: :all).count == 12 } # 10 users + back + show more button

        expect(page).to have_css("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers[organization-member-limit='10']")
        scroll_into_view('li.js-showMoreMembers')
        page.find("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers").click
        wait.until { page.all("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li", visible: :all).count == 27 } # 25 users + back + show more button

        expect(page).to have_css("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers[organization-member-limit='25']")
        scroll_into_view('li.js-showMoreMembers')
        page.find("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers").click
        wait.until { page.all("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li", visible: :all).count == 28 } # 26 users + back + show more button

        scroll_into_view('li.js-showMoreMembers')
        expect(page).to have_css("ul.recipientList-organizationMembers[organization-id='#{organization.id}'] li.js-showMoreMembers.hidden", visible: :all)
      end
    end
  end

  describe 'Invalid group and owner list for tickets created via customer profile #3835' do
    let(:invalid_ticket) { create(:ticket) }

    before do
      visit "#ticket/create/id/#{invalid_ticket.id}/customer/#{User.find_by(firstname: 'Nicole').id}"
    end

    it 'does show an empty list of owners' do
      wait.until { page.all('select[name=owner_id] option').one? }
      expect(page.all('select[name=owner_id] option').count).to eq(1)
    end
  end

  describe 'Assign user to multiple organizations #1573' do
    let(:organization1) { create(:organization) }
    let(:organization2) { create(:organization) }
    let(:organization3) { create(:organization) }
    let(:organization4) { create(:organization) }
    let(:user1)         { create(:agent, organization: organization1, organizations: [organization2, organization3]) }
    let(:user2)         { create(:agent, organization: organization4) }
    let(:customer1)     { create(:customer, organization: organization1, organizations: [organization2, organization3]) }
    let(:customer2)     { create(:customer, organization: organization4) }

    context 'when agent', authenticated_as: :authenticate do
      def authenticate
        user1
        user2
        true
      end

      before do
        visit 'ticket/create'
      end

      it 'does show the organization field for user 1' do
        find('[name=customer_id_completion]').fill_in with: user1.firstname
        find("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").click
        expect(page).to have_css("div[data-attribute-name='organization_id']")
      end

      it 'does not show the organization field for user 2' do
        find('[name=customer_id_completion]').fill_in with: user2.firstname
        find("li.recipientList-entry.js-object[data-object-id='#{user2.id}']").click
        await_empty_ajax_queue
        expect(page).to have_no_css("div[data-attribute-name='organization_id']")
      end

      it 'can create tickets for secondary organizations' do
        fill_in 'Title', with: 'test'
        find('.richtext-content').send_keys 'test'
        set_tree_select_value('group_id', Group.first.name)

        find('[name=customer_id_completion]').fill_in with: user1.firstname
        wait.until { page.all("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").present? }
        find("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").click

        find('div[data-attribute-name=organization_id] .js-input').fill_in with: user1.organizations[0].name, fill_options: { clear: :backspace }
        wait.until { page.all("div[data-attribute-name=organization_id] .js-option[data-value='#{user1.organizations[0].id}']").present? }
        page.find("div[data-attribute-name=organization_id] .js-option[data-value='#{user1.organizations[0].id}'] span").click

        click '.js-submit'
        wait.until { Ticket.last.organization_id == user1.organizations[0].id }
      end

      it 'restores saved organization selection correctly (#5347)' do
        find('[name=customer_id_completion]').fill_in with: user1.firstname
        wait.until { page.all("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").present? }
        find("li.recipientList-entry.js-object[data-object-id='#{user1.id}']").click

        find('div[data-attribute-name=organization_id] .js-input').fill_in with: organization2.name, fill_options: { clear: :backspace }
        wait.until { page.all("div[data-attribute-name=organization_id] .js-option[data-value='#{organization2.id}']").present? }

        taskbar_timestamp = Taskbar.last.updated_at

        page.find("div[data-attribute-name=organization_id] .js-option[data-value='#{organization2.id}'] span").click

        wait.until { Taskbar.last.updated_at != taskbar_timestamp }

        refresh

        expect(find('div[data-attribute-name=organization_id] .js-input').value).to eq(organization2.name)
      end
    end

    context 'when customer' do
      before do
        visit 'customer_ticket_new'
      end

      it 'does show the organization field for user 1', authenticated_as: :customer1 do
        expect(page).to have_css("div[data-attribute-name='organization_id']")
      end

      it 'does not show the organization field for user 2', authenticated_as: :customer2 do
        expect(page).to have_field('title')
        await_empty_ajax_queue
        expect(page).to have_no_css("div[data-attribute-name='organization_id']")
      end

      it 'can create tickets for secondary organizations', authenticated_as: :customer1 do
        fill_in 'Title', with: 'test'
        find('.richtext-content').send_keys 'test'
        set_tree_select_value('group_id', Group.first.name)
        find('div[data-attribute-name=organization_id] .js-input').fill_in with: customer1.organizations[0].name, fill_options: { clear: :backspace }
        wait.until { page.all("div[data-attribute-name=organization_id] .js-option[data-value='#{customer1.organizations[0].id}']").present? }
        page.find("div[data-attribute-name=organization_id] .js-option[data-value='#{customer1.organizations[0].id}'] span").click
        click '.js-submit'
        wait.until { Ticket.last.organization_id == customer1.organizations[0].id }
      end
    end
  end

  describe 'Wrong default values in ticket create when creating from user profile #4088' do
    let(:customer) { create(:customer) }

    before do
      visit "ticket/create/customer/#{customer.id}"
    end

    it 'does show the default state when creating a ticket from a user profile' do
      expect(page).to have_select('state_id', selected: 'open')
    end
  end

  describe 'Open ticket indicator coloring setting' do
    let(:elem)        { find('[data-tab="customer"]') }
    let(:customer)    { create(:customer) }
    let(:group)       { Group.first }

    before do
      Setting.set 'ui_sidebar_open_ticket_indicator_colored', state

      customer.preferences[:tickets_open] = tickets_count
      customer.save!

      visit 'ticket/create'

      field = find '[name=customer_id]', visible: :hidden

      field.execute_script "this.value = #{customer.id}"
      field.execute_script '$(this).trigger("change")'
    end

    context 'when enabled' do
      let(:state) { true }

      context 'with 1 ticket' do
        let(:tickets_count) { 1 }

        it 'highlights as warning' do
          create(:ticket, customer: customer, group: group)

          expect(elem)
            .to have_no_css('.tabsSidebar-tab-count--danger')
            .and have_css('.tabsSidebar-tab-count--warning')
        end
      end

      context 'with 2 tickets' do
        let(:tickets_count) { 2 }

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

  describe 'Required value group_id is missing during ticket creation via web #5590', authenticated_as: :authenticate do
    let(:group_1) { create(:group) }
    let(:group_2) { create(:group, parent_id: group_1.id) }

    def authenticate
      group_1
      group_2
      Setting.set('customer_ticket_create_group_ids', [group_2.id.to_s])
      create(:customer)
    end

    before do
      visit '#customer_ticket_new'
    end

    it 'does create a ticket' do
      fill_in 'Title', with: 'test'
      find('.richtext-content').send_keys 'test'
      click '.js-submit'
      wait.until { Ticket.last.group_id == group_2.id }
    end
  end
end
