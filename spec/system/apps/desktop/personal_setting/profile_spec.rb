# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Personal Setting > Profile', app: :desktop_view, authenticated_as: :agent, type: :playwright do
  let(:agent) { create(:agent) }

  let(:theme)     { page.locator('html') }
  let(:user_menu) { page.get_by_role('button', name: agent.fullname, exact: true) }

  before do
    open_desktop('/')
    user_menu.click
  end

  def open_personal_settings(section)
    page.get_by_role('link', name: 'Personal settings').click
    page.get_by_role('complementary', name: 'Personal settings').get_by_role('link', name: section, exact: true).click
  end

  describe 'appearance selection' do
    it 'user can switch appearance' do
      # Switch starts on 'auto'
      default_theme = page.evaluate("matchMedia('(prefers-color-scheme: dark)').matches") ? 'dark' : 'light'
      expect(theme).to have_attribute('data-theme', default_theme)

      appearance = page.get_by_role('button', name: 'Appearance')

      appearance.click
      wait_for_mutation('userCurrentAppearance')
      expect(theme).to have_attribute('data-theme', 'dark')

      appearance.click
      wait_for_mutation('userCurrentAppearance', number: 2)
      expect(theme).to have_attribute('data-theme', 'light')
    end
  end

  describe 'language selection' do
    it 'user can change language' do
      open_personal_settings('Language')

      select_option('User interface language', 'Deutsch')

      expect(main_content).to contain_text('Sprache')
    end
  end

  describe 'overview configuration' do
    before do
      create(:overview, name: 'Test Overview')
    end

    it 'user can change overview order' do
      open_personal_settings('Overviews')

      overviews = main_content.get_by_role('list', name: 'Overview order list').get_by_role('listitem')

      # In this order, other overviews may sit in between.
      expect(overviews).to contain_text(['Test Overview', 'My Assigned Tickets'])

      overviews.filter(hasText: 'Test Overview').drag_to(overviews.filter(hasText: 'My Assigned Tickets'))

      expect(overviews).to contain_text(['My Assigned Tickets', 'Test Overview'])

      page_navigation.get_by_role('link', name: 'Overviews').click

      expect(main_content).to contain_text(%r{My Assigned Tickets\s*0\s*Test Overview})
    end
  end

  describe 'avatar handling', authenticated_as: :agent do
    let(:agent) { create(:agent, firstname: 'Jane', lastname: 'Doe') }

    it 'user can upload avatar' do
      open_personal_settings('Avatar')

      expect(main_content).to contain_text('JD')
      file_chooser = page.expect_file_chooser { main_content.get_by_role('button', name: 'Upload').click }
      file_chooser.set_files(Rails.root.join('test/data/image/1000x1000.png').to_s)

      crop_image = flyout('Crop image')
      expect(crop_image).to contain_text('Avatar preview')
      crop_image.get_by_role('button', name: 'Save', exact: true).click

      expect(notification('Your avatar has been uploaded')).to be_visible

      # The avatar inside the user menu is hidden from assistive technology, the button names the user.
      expect(user_menu.get_by_label("Avatar (#{agent.fullname})", exact: true))
        .to have_css('background-image', %r{/api/v1/users/image/#{Avatar.last.store_hash}})
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

      open_personal_settings('Calendar')
    end

    def subscription_url(label)
      input = page.get_by_label(label, exact: true)
      expect(input).to not_have_value('')
      input.input_value
    end

    it 'user can use combined subscription URL' do
      page.goto(subscription_url('Combined subscription URL'))

      expect(page.locator('body')).to contain_text("new ticket: 'Normal ticket'")
      expect(page.locator('body')).to contain_text("ticket escalation: 'Escalated ticket'")
    end

    it 'user can use direct subscription URL' do
      field('Not assigned').get_by_role('switch').click
      expect(notification('Your calendar subscription settings were updated.')).to be_visible

      page.goto(subscription_url('Direct subscription URL'))
      expect(page.locator('body')).to not_contain_text("new ticket: 'Normal ticket'")
      expect(page.locator('body')).to contain_text("ticket escalation: 'Escalated ticket'")
    end
  end
end
