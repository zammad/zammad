# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_navigation_and_title_test.rb as a continuous
#   end-to-end scenario: page title, navigation highlight and active task survive
#   a `ui:rerender` event and a full page reload on every major screen. The plain
#   title values are partly covered by keyboard_shortcuts_spec as well.
RSpec.describe 'Scenario > Navigation highlight and page title', authenticated_as: :authenticate, type: :system do
  let(:group)  { Group.find_by(name: 'Users') }
  let(:ticket) { create(:ticket, group:, title: 'navigation title check') }

  def authenticate
    ticket

    create(:admin, groups: [group])
  end

  def rerender
    execute_script("App.Event.trigger('ui:rerender')")
  end

  def expect_dashboard_state
    expect(page).to have_title('Dashboard')
    expect(page).to have_css('#navigation .js-menu .js-dashboardMenuItem.is-active')
    expect(page).to have_no_css('#navigation .tasks .js-item.is-active')
  end

  def expect_zoom_state
    expect(page).to have_title(ticket.title)
    expect(page).to have_css('#navigation .tasks .task.is-active', text: ticket.title)
    expect(page).to have_no_css('#navigation .js-menu .is-active')
  end

  def expect_manage_state
    expect(page).to have_title('Users')
    expect(page).to have_no_css('#navigation .js-menu .is-active')
    expect(page).to have_no_css('#navigation .tasks .js-item.is-active')
  end

  it 'keeps titles and highlights stable across rerender and reload' do
    # Dashboard after login.
    visit 'dashboard'

    expect_dashboard_state
    rerender
    expect_dashboard_state
    page.refresh
    expect_dashboard_state

    # Ticket zoom: title follows the ticket, task is active, no menu highlight.
    visit "#ticket/zoom/#{ticket.id}"

    expect_zoom_state
    rerender
    expect_zoom_state
    page.refresh
    expect_zoom_state

    # Back to the dashboard via click.
    find('#navigation a[href="#dashboard"]').click

    expect_dashboard_state
    rerender
    expect_dashboard_state
    page.refresh
    expect_dashboard_state

    # Admin area: Users title, neither menu nor task highlighted.
    find('a[href="#manage"]').click

    expect_manage_state
    rerender
    expect_manage_state
    page.refresh
    expect_manage_state
  end
end
