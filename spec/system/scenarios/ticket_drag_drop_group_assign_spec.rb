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
    click_and_hold(element)

    # Starting the drag re-fetches the overview's form meta (owner_id per group),
    #   which the assign entries are rendered from once - let it settle first, or
    #   a still-in-flight request (e.g. the heavier role-based access resolution)
    #   can leave a stale/incomplete entry list baked into the overlay's markup.
    await_empty_ajax_queue

    move_mouse_by(0, 20)
    move_mouse_by(3, 0)

    # The assign circle rests below the viewport edge - move the held ticket to
    #   the bottom area inside the viewport to let it slide up and expand.
    #
    # The overlay expands once the cursor's page Y crosses the assign panel's
    #   own top edge, which shifts with the number of rendered group/user
    #   entries - targeting a fixed viewport-relative Y (e.g. "innerHeight -
    #   60") can land above that edge on a taller render and leave the drag
    #   stuck with the circles shown but never expanded. Read the panel's
    #   actual (unanimated, so unaffected by its slide-in transform) top edge
    #   instead, so the target always lands inside its trigger zone.
    circle         = page.find('.js-batch-assign-circle', visible: :all)
    assign_box_top = page.evaluate_script("document.querySelector('.js-batch-assign').getBoundingClientRect().top")
    target_y       = assign_box_top + 20

    slide_mouse_to(circle, x_offset: 20, y_coord: target_y)

    # Pinpoint a stuck drag right here instead of downstream: if the cursor
    #   never crossed into the assign zone, the panel never expands and every
    #   `.batch-overlay-assign-entry` lookup below fails anonymously.
    expect(page).to have_css('.js-batch-assign', visible: :visible),
                    'the assign overlay never expanded - the drag did not reach the assign drop zone'
  end

  def expect_group_assign_entry(new_group)
    visit 'ticket/view/all_unassigned'

    within(:active_content) do
      expect(page).to have_text(ticket.title)
    end

    drag_ticket_to_batch_overlay

    entry = find(".batch-overlay-assign-entry[data-action='group_assign']", text: %r{#{Regexp.quote(new_group.name)}}i)

    expect(entry).to have_text(%r{1 people}i)

    # Hovering while the assign panel is still sliding in makes the driver
    #   scroll the overlay (overflow: hidden, but still programmatically
    #   scrollable) to reach the not-yet-in-view target. That inner scroll
    #   shifts the settled panel above the drop zone offset stored at drag
    #   start, so the hover's own mousemove registers as "middle area",
    #   collapses the panel under the cursor, and the resulting mouseleave
    #   silently cancels the sub-panel render timer. Let the slide-in settle
    #   first, so the hover is a plain in-view mouse move.
    wait(5, interval: 0.2).until_constant do
      page.evaluate_script("document.querySelector('.js-batch-assign').getBoundingClientRect().top")
    end

    # The member list is populated by a hover listener bound to this inner node
    #   (not the padded outer entry box), which only fires once its own delayed
    #   render timer completes - hover it directly rather than relying on the
    #   outer box's bounding-box center to land on it.
    entry.find('.js-batch-hover-target').hover

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
