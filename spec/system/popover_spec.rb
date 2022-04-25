# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Popover', type: :system do

  # This test covers generic PopoverProvidable behavior
  it 'opening & auto-closing' do
    visit "#ticket/zoom/#{Ticket.first.id}"

    within :active_content do
      find('.ticketZoom-header .js-avatar').hover
    end

    # popover opened up
    expect(page).to have_css('.popover')

    visit '#dashboard'

    # move mouse to another location
    # for reliable popover re-spawning
    find('.menu').hover

    # popover is not visible when moving to another page without moving mouse
    # https://github.com/zammad/zammad/issues/4058
    expect(page).to have_no_css('.popover')

    visit "#ticket/zoom/#{Ticket.first.id}"

    # popover is not visible when moving back to the original page without moving mouse
    expect(page).to have_no_css('.popover')

    within :active_content do
      find('.ticketZoom-header .js-avatar').hover
    end

    # popover opens up again
    expect(page).to have_css('.popover')
  end
end
