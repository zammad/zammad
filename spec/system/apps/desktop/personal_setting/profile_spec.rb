# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

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
end
