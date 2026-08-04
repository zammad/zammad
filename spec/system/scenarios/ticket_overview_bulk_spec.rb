# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_overview_level0_test.rb as end-to-end scenarios:
#   bulk state changes from an overview including the overview counter, the column
#   settings dialog with reload persistence, the conditional pending time field and
#   the change-permission dependent visibility of the bulk form (#2026, #1864).
RSpec.describe 'Scenario > Ticket overview bulk actions and settings', type: :system do
  let(:group) { Group.find_by(name: 'Users') }

  def overview_count
    find('a[href="#ticket/view/all_unassigned"] .badge').text.to_i
  end

  def select_bulk(ticket)
    find("tr[data-id='#{ticket.id}']").check('bulk', allow_label_click: true)
  end

  describe 'bulk close, overview counter and column settings', authenticated_as: :authenticate, sessions_jobs: true do
    let(:ticket1) { create(:ticket, group:, title: 'overview count test #1') }
    let(:ticket2) { create(:ticket, group:, title: 'overview count test #2') }

    def authenticate
      ticket1 && ticket2

      create(:admin, groups: [group])
    end

    it 'closes tickets in bulk, decrements the counter and persists column settings' do
      visit 'ticket/view/all_unassigned'

      within(:active_content) do
        expect(page).to have_text(ticket2.title)
      end

      count_before = overview_count

      within(:active_content) do
        select_bulk(ticket1)
        select_bulk(ticket2)

        select 'closed', from: 'state_id'
        click '.js-confirm'
        click '.js-submit'

        expect(page).to have_no_css("tr[data-id='#{ticket1.id}']")
        expect(page).to have_no_css("tr[data-id='#{ticket2.id}']")
      end

      expect(page).to have_css('a[href="#ticket/view/all_unassigned"] .badge', text: (count_before - 2).to_s)

      # A new ticket increments the counter, closing it decrements again.
      ticket3 = create(:ticket, group:, title: 'overview count test #3')

      expect(page).to have_css('a[href="#ticket/view/all_unassigned"] .badge', text: (count_before - 1).to_s, wait: 30)

      ticket3.update!(state: Ticket::State.lookup(name: 'closed'))

      expect(page).to have_css('a[href="#ticket/view/all_unassigned"] .badge', text: (count_before - 2).to_s, wait: 30)

      # Enable additional columns via the settings dialog.
      within(:active_content) do
        click '[data-type="settings"]'
      end

      in_modal do
        %w[number title customer group created_at article_count].each do |column|
          checkbox = find("input[value='#{column}']", visible: :all)
          checkbox.click if !checkbox.checked?
        end

        click '.js-submit'
      end

      within(:active_content) do
        expect(page).to have_css('table th:nth-child(3)', text: '#')
        expect(page).to have_css('table th:nth-child(4)', text: %r{title}i)
        expect(page).to have_css('table th:nth-child(7)', text: %r{article#}i)
      end

      # The column settings survive a reload.
      page.refresh

      within(:active_content) do
        expect(page).to have_css('table th:nth-child(3)', text: '#')
        expect(page).to have_css('table th:nth-child(4)', text: %r{title}i)
        expect(page).to have_css('table th:nth-child(7)', text: %r{article#}i)

        # Disable the extra columns again: title moves up, article count disappears.
        click '[data-type="settings"]'
      end

      in_modal do
        %w[number article_count].each do |column|
          checkbox = find("input[value='#{column}']", visible: :all)
          checkbox.click if checkbox.checked?
        end

        click '.js-submit'
      end

      within(:active_content) do
        expect(page).to have_css('table th:nth-child(3)', text: %r{title}i)
        expect(page).to have_no_css('table th', text: %r{article#}i)
      end
    end
  end

  describe 'bulk pending state with conditional pending time', authenticated_as: :authenticate do
    let(:admin_user) { create(:admin, firstname: 'Bulk', lastname: 'Admin', groups: [group]) }
    let(:ticket1)    { create(:ticket, group:, title: 'bulk pending test #1') }
    let(:ticket2)    { create(:ticket, group:, title: 'bulk pending test #2') }

    def authenticate
      ticket1 && ticket2

      admin_user
    end

    it 'reveals the pending time only for pending states and applies the bulk change' do
      visit 'ticket/view/all_unassigned'

      within(:active_content) do
        select_bulk(ticket1)
        select_bulk(ticket2)

        expect(page).to have_css('.bulkAction [data-name="pending_time"]', visible: :hidden)

        select 'pending close', from: 'state_id'

        expect(page).to have_css('.bulkAction [data-name="pending_time"]', visible: :visible)

        find('.bulkAction [data-item="date"]').fill_in with: '05/23/2037'

        find('.bulkAction [data-attribute-name="group_id"] .js-input').click
        click 'li', text: group.name
        select admin_user.fullname, from: 'owner_id'

        click '.js-confirm'
        click '.js-submit'

        expect(page).to have_no_css("tr[data-id='#{ticket1.id}']")
        expect(page).to have_no_css("tr[data-id='#{ticket2.id}']")
      end

      expect(ticket1.reload.state.name).to eq('pending close')
      expect(ticket2.reload.owner).to eq(admin_user)
    end
  end

  describe 'bulk owner change (#1864)', authenticated_as: :authenticate do
    let(:admin_user) { create(:admin, firstname: 'Owner', lastname: 'Admin', groups: [group]) }
    let(:ticket1)    { create(:ticket, group:, title: 'bulk owner test #1') }
    let(:ticket2)    { create(:ticket, group:, title: 'bulk owner test #2') }

    def authenticate
      ticket1 && ticket2

      admin_user
    end

    it 'changes owner and state of the selected tickets' do
      visit 'ticket/view/all_unassigned'

      within(:active_content) do
        select_bulk(ticket1)
        select_bulk(ticket2)

        select admin_user.fullname, from: 'owner_id'
        select 'closed',            from: 'state_id'

        click '.js-confirm'
        click '.js-submit'

        expect(page).to have_no_css("tr[data-id='#{ticket1.id}']")
        expect(page).to have_no_css("tr[data-id='#{ticket2.id}']")
      end

      expect(ticket1.reload).to have_attributes(owner: admin_user, state: Ticket::State.lookup(name: 'closed'))
    end
  end

  describe 'bulk form visibility depends on change permission (#2026)', authenticated_as: :authenticate do
    let(:other_group)   { create(:group, name: 'Bulk change group') }
    let(:agent_user)    { create(:agent) }
    let(:can_change)    { create(:ticket, group: other_group, title: 'can change ticket') }
    let(:cannot_change) { create(:ticket, group:, title: 'cannot change ticket') }

    def authenticate
      can_change && cannot_change

      agent_user.group_names_access_map = {
        other_group.name => 'full',
        group.name       => %w[read create overview],
      }
      agent_user.save!
      agent_user
    end

    it 'hides the bulk form as soon as an unchangeable ticket is selected' do
      visit 'ticket/view/all_unassigned'

      within(:active_content) do
        select_bulk(can_change)

        expect(page).to have_css('.bulkAction', visible: :visible)

        select_bulk(cannot_change)

        expect(page).to have_css('.bulkAction', visible: :hidden)

        find("tr[data-id='#{cannot_change.id}']").uncheck('bulk', allow_label_click: true)

        expect(page).to have_css('.bulkAction', visible: :visible)

        find("tr[data-id='#{can_change.id}']").uncheck('bulk', allow_label_click: true)

        expect(page).to have_css('.bulkAction', visible: :hidden)
      end
    end
  end
end
