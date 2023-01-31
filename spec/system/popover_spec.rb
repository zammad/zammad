# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

  it 'popover in overviews closes after overview update', ensure_threads_exited: true do
    ensure_websocket do
      visit '#ticket/view/all_unassigned'
    end

    within :active_content do
      find('.user-popover').hover
    end

    expect(page).to have_css('.popover')

    Ticket.find(1).update!(owner: current_user)

    ensure_block_keeps_running do
      Sessions.thread_client(Sessions.sessions.first, 0, Time.now.utc, nil)
    end

    expect(page).to have_no_css('.popover')
  end

  it 'popover of another agent closes after taskbar update' do
    ensure_websocket do
      visit "#ticket/zoom/#{Ticket.first.id}"
    end

    taskbar = Taskbar.where(key: 'Ticket-1', user_id: current_user.id).first
    allow(taskbar).to receive(:update_preferences_infos)

    within :active_content do
      taskbar.update! preferences: { 'tasks' => [{
        'user_id' => create(:admin).id,
        'apps'    => taskbar.preferences['tasks'].first['apps'],
      }] }
      TransactionDispatcher.commit

      find('.js-attributeBar .user-popover').hover
    end

    expect(page).to have_css('.popover')

    taskbar.update! preferences: { 'tasks' => [] }
    TransactionDispatcher.commit

    expect(page).to have_no_css('.popover')
  end
end
