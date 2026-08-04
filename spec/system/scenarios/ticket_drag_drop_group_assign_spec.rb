# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/admin_drag_drop_to_new_group_test.rb as end-to-end
#   scenarios: dragging a ticket in the overview opens the batch overlay, where a
#   newly created group appears as group assign target with its member resolved -
#   both for membership via role and via direct group access.
RSpec.describe 'Scenario > Ticket drag and drop group assignment', authenticated_as: :authenticate, type: :system do
  let(:group)  { Group.find_by(name: 'Users') }
  let(:ticket) { create(:ticket, group:, title: 'drag drop assign test') }

  def drag_ticket_to_batch_overlay
    element = page.find(:table_row, ticket.id).native

    # Start dragging to open the batch overlay, then move the held ticket onto
    #   the lower assign circle, which expands into the group assign entries.
    page.driver.browser.action
      .move_to_location(element.location.x + 50, element.location.y + 10)
      .click_and_hold
      .move_by(0, 20)
      .move_by(3, 0)
      .perform

    # The assign circle rests below the viewport edge - move the held ticket to
    #   the bottom area inside the viewport to let it slide up and expand.
    circle   = page.find('.js-batch-assign-circle', visible: :all).native
    target_y = page.evaluate_script('window.innerHeight') - 60

    page.driver.browser.action
      .move_to_location(circle.location.x + 20, target_y)
      .perform
  end

  def expect_group_assign_entry(new_group)
    visit 'ticket/view/all_unassigned'

    within(:active_content) do
      expect(page).to have_text(ticket.title)
    end

    drag_ticket_to_batch_overlay

    entry = find(".batch-overlay-assign-entry[data-action='group_assign']", text: %r{#{Regexp.quote(new_group.name)}}i)

    expect(entry).to have_text(%r{1 people}i)

    entry.hover

    expect(page).to have_css(".js-batch-assign-group-inner .batch-overlay-assign-entry[data-action='user_assign']", count: 1)
  end

  context 'when the group membership comes from a role' do
    let(:new_group) { create(:group, name: 'Drag role group') }
    let(:role)      do
      create(:role, permission_names: %w[ticket.agent]).tap do |r|
        r.group_names_access_map = { new_group.name => 'full' }
        r.save!
      end
    end

    def authenticate
      ticket

      create(:admin, groups: [group]).tap { |user| user.roles << role }
    end

    it 'offers the new group with its member as assign target' do
      expect_group_assign_entry(new_group)
    end
  end

  context 'when the group membership is assigned directly' do
    let(:new_group) { create(:group, name: 'Drag direct group') }

    def authenticate
      ticket

      create(:admin, groups: [group, new_group])
    end

    it 'offers the new group with its member as assign target' do
      expect_group_assign_entry(new_group)
    end
  end
end
