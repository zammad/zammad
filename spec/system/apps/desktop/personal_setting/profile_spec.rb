# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Personal Setting > Profile', app: :desktop_view, authenticated_as: :agent, type: :system do
  let(:agent) { create(:agent) }

  before do
    visit '/'
    find("[aria-label=\"Avatar (#{agent.fullname})\"]").click
  end

  describe 'appearance selection' do
    it 'user can switch appearance' do
      # Switch starts on 'auto'
      default_theme = page.execute_script("return matchMedia('(prefers-color-scheme: dark)').matches") ? 'dark' : 'light'
      expect(page).to have_css("html[data-theme=#{default_theme}]")

      # Switch to 'dark'
      click_on 'Appearance'
      wait_for_mutation('userCurrentAppearance')
      expect(page).to have_css('html[data-theme=dark]')

      # Switch to 'light'
      click_on 'Appearance'
      wait_for_mutation('userCurrentAppearance', number: 2)
      expect(page).to have_css('html[data-theme=light]')

    end
  end

  describe 'language selection' do
    it 'user can change language' do
      click_on 'Profile settings'
      click_on 'Language'

      find('label', text: 'Your language').click
      find('span', text: 'Deutsch').click

      expect(page).to have_text('Sprache')
    end
  end

  describe 'overview configuration' do
    before do
      create(:overview, name: 'Test Overview')
    end

    it 'user can change overview order' do
      click_on 'Profile settings'

      within '#personal-settings-sidebar' do
        click_on 'Overviews'
      end

      expect(page).to have_text("Test Overview\nMy Assigned Tickets")

      o1 = find('li.draggable', text: 'Test Overview')
      o2 = find('li.draggable', text: 'My Assigned Tickets')
      o1.drag_to(o2)

      expect(page).to have_text('The order of your ticket overviews was updated.')
      expect(page).to have_text("My Assigned Tickets\nTest Overview")

      within '#page-navigation' do
        click_on 'Overviews'
      end
      expect(page).to have_text("My Assigned Tickets\n0\nTest Overview")
    end
  end

  describe 'avatar handling', authenticated_as: :agent do
    let(:agent) { create(:agent, firstname: 'Jane', lastname: 'Doe') }

    it 'user can upload avatar' do
      click_on 'Profile settings'
      click_on 'Avatar'

      expect(page).to have_text('JD')
      find('input[data-test-id="fileUploadInput"]', visible: :all).set(Rails.root.join('test/data/image/1000x1000.png'))
      expect(page).to have_text('Avatar Preview')
      click_on 'Save'

      expect(page).to have_text('Your avatar has been uploaded')

      avatar_element_style = find("#user-menu span[aria-label=\"Avatar (#{agent.fullname})\"]").style('background-image')
      expect(avatar_element_style['background-image']).to include("/api/v1/users/image/#{Avatar.last.store_hash}")
    end
  end

  describe 'calendar handling', authenticated_as: :agent do
    let(:group)            { create(:group) }
    let(:agent)            { create(:agent, firstname: 'Jane', lastname: 'Doe', groups: [group]) }
    let(:ticket)           { create(:ticket, title: 'Normal ticket', owner: agent, group:) }
    let(:escalated_ticket) { create(:ticket, title: 'Escalated ticket', owner: agent, group:) }

    before do
      ticket.update_columns(escalation_at: 2.weeks.from_now)
      escalated_ticket.update_columns(escalation_at: 2.weeks.ago)

      click_on 'Profile settings'
      click_on 'Calendar'
    end

    it 'user can use combined subscription URL' do
      visit(find_input('Combined subscription URL').input_element.value)

      expect(page).to have_text("new ticket: 'Normal ticket'")
      expect(page).to have_text("ticket escalation: 'Escalated ticket'")
    end

    it 'user can use direct subscription URL' do
      find_toggle('Not assigned').toggle_on
      expect(page).to have_text('You calendar subscription settings were updated.')

      visit(find_input('Direct subscription URL').input_element.value)
      expect(page).to have_no_text("new ticket: 'Normal ticket'")
      expect(page).to have_text("ticket escalation: 'Escalated ticket'")
    end
  end
end
