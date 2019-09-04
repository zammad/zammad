require 'rails_helper'

RSpec.describe 'Ticket views', type: :system do

  let!(:group1)              { create :group }
  let!(:group2)              { create :group }
  let!(:macro_without_group) { create :macro }
  let!(:macro_group1)        { create :macro, groups: [group1] }
  let!(:macro_group2)        { create :macro, groups: [group2] }

  it 'supports group-dependent macros' do

    ticket1 = create :ticket, group: group1
    ticket2 = create :ticket, group: group2

    # give user access to all groups including those created
    # by using FactoryBot outside of the example
    group_names_access_map = Group.all.pluck(:name).each_with_object({}) do |group_name, result|
      result[group_name] = 'full'.freeze
    end

    current_user do |user|
      user.group_names_access_map = group_names_access_map
      user.save!
    end

    # refresh browser to get macro accessable
    refresh
    visit '#ticket/view/all_open'

    within(:active_content) do

      ticket = page.find(:table_row, 1).native

      # click and hold first ticket in table
      click_and_hold(ticket)

      # move ticket to y -ticket.location.y
      move_mouse_by(0, -ticket.location.y + 5)

      # move a bit to the left to display macro batches
      move_mouse_by(-250, 0)

      expect(page).to have_selector(:macro_batch, macro_without_group.id, visible: true)
      expect(page).to have_no_selector(:macro_batch, macro_group1.id)
      expect(page).to have_no_selector(:macro_batch, macro_group2.id)

      release_mouse

      refresh

      ticket = page.find(:table_row, ticket1.id).native

      # click and hold first ticket in table
      click_and_hold(ticket)

      # move ticket to y -ticket.location.y
      move_mouse_by(0, -ticket.location.y + 5)

      # move a bit to the left to display macro batches
      move_mouse_by(-250, 0)

      expect(page).to have_selector(:macro_batch, macro_without_group.id, visible: true)
      expect(page).to have_selector(:macro_batch, macro_group1.id)
      expect(page).to have_no_selector(:macro_batch, macro_group2.id)

      release_mouse

      refresh

      ticket = page.find(:table_row, ticket2.id).native

      # click and hold first ticket in table
      click_and_hold(ticket)

      # move ticket to y -ticket.location.y
      move_mouse_by(0, -ticket.location.y + 5)

      # move a bit to the left to display macro batches
      move_mouse_by(-250, 0)

      expect(page).to have_selector(:macro_batch, macro_without_group.id, visible: true)
      expect(page).to have_no_selector(:macro_batch, macro_group1.id)
      expect(page).to have_selector(:macro_batch, macro_group2.id)

    end
  end
end
