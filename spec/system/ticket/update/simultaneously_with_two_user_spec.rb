# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket > Update > Simultaneously with two different user', type: :system do
  let(:group)  { Group.find_by(name: 'Users') }
  let(:ticket) { create(:ticket, group: group) }
  let(:agent)  { User.find_by(login: 'agent1@example.com') }

  # rubocop:disable RSpec/InstanceVariable
  define :have_avatar do |expected|
    chain(:changed, :text)

    match do
      elem = find_element

      return false if elem.nil?

      return true if !@icon && !@no_icon

      return elem.has_no_css? '.icon' if @no_icon

      elem.has_css? ".icon-#{@icon}"
    end

    def find_element
      if expected.is_a? User
        actual.find "#{base_selector}#{select_by_user}"
      else
        actual.find base_selector, text: expected
      end
    rescue
      nil
    end

    match_when_negated do
      if expected.is_a? User
        return actual.has_no_css? "#{base_selector}#{select_by_user}"
      end

      actual.has_no_css? base_selector, text: expected
    end

    chain :changed! do
      @changed = true
    end

    chain :with_icon do |icon|
      @icon = icon
    end

    chain :with_no_icon! do
      @no_icon = true
    end

    def select_by_user
      "[data-id='#{expected.id}']"
    end

    def base_selector
      changed_class = @changed ? 'changed' : 'not-changed'

      ".js-attributeBar .js-avatar .avatar--#{changed_class}"
    end
  end
  # rubocop:enable RSpec/InstanceVariable

  def check_taskbar_tab(ticket_id, title: nil, modified: false)
    tab_data_key = "Ticket-#{ticket_id}"

    if title
      taskbar_tab = find(".tasks .task[data-key='#{tab_data_key}']")
      expect(taskbar_tab).to have_css('.nav-tab-name', text: title)
    end

    if modified
      expect(page).to have_css(".tasks .task[data-key='#{tab_data_key}'].is-modified")
    else
      expect(page).to have_no_css(".tasks .task[data-key='#{tab_data_key}'].is-modified")
    end
  end

  context 'when two different users are simultaneously in one ticket' do
    before do
      visit "#ticket/zoom/#{ticket.id}"

      using_session(:second_browser) do
        login(
          username: agent.login,
          password: 'test',
        )

        visit "#ticket/zoom/#{ticket.id}"
      end
    end

    it 'avatar from other user should be visible in ticket zoom' do
      expect(page).to have_avatar('AT')

      using_session(:second_browser) do
        expect(page).to have_avatar('TA')
      end
    end

    it 'check changes from the first user and added changes from the second user' do
      within(:active_content) do
        find('.js-textarea').send_keys('some note')

        expect(page).to have_css('.js-reset')
      end

      expect(page).to have_avatar('AT')

      using_session(:second_browser) do
        expect(page).to have_avatar('TA').changed!

        within(:active_content) do
          find('.js-textarea').send_keys('some other note')

          expect(page).to have_css('.js-reset')
        end
      end

      expect(page).to have_avatar('AT').changed!

      using_session(:second_browser) do
        within(:active_content) do
          click '.js-attributeBar .js-submit'

          expect(page).to have_no_css('.js-reset')
          expect(page).to have_css('.article-content', text: 'some other note')
        end

        expect(page).to have_avatar('TA').changed!
      end

      expect(page).to have_avatar('AT')
      check_taskbar_tab(ticket.id, title: ticket.title, modified: true)

      within(:active_content) do
        expect(page).to have_css('.article-content', text: 'some other note')

        click '.js-attributeBar .js-submit'

        expect(page).to have_no_css('.js-reset')
        expect(page).to have_css('.article-content', text: 'some note')
      end

      using_session(:second_browser) do
        expect(page).to have_avatar('TA')

        expect(page).to have_css('.article-content', text: 'some note')
        check_taskbar_tab(ticket.id, title: ticket.title, modified: true)
      end

      # Reload browsers and check if state is correct.
      refresh

      using_session(:second_browser) do
        refresh

        expect(page).to have_avatar('TA')
        expect(page).to have_no_css('.js-reset')
      end

      expect(page).to have_avatar('AT')
      expect(page).to have_no_css('.js-reset')
    end

    it 'check refresh for unsaved changes and reset after refresh' do
      using_session(:second_browser) do
        within(:active_content) do
          find('.js-textarea').send_keys('some other note')

          expect(page).to have_css('.js-reset')
        end

        expect(page).to have_avatar('TA')

        # We need to wait for the auto save feature.
        wait.until do
          Taskbar.find_by(key: "Ticket-#{ticket.id}", user_id: agent.id).state_changed?
        end

        refresh
      end

      expect(page).to have_avatar('AT').changed!

      using_session(:second_browser) do
        refresh

        within(:active_content) do
          click '.js-reset'
          expect(page).to have_css('.js-textarea', text: '')
        end
      end

      expect(page).to have_avatar('AT')
    end

    it 'change title with second user' do
      find('.js-textarea').send_keys('some note')

      using_session(:second_browser) do
        find('.js-textarea').send_keys('some other note')
        find('.js-objectTitle').set('TTTsome level 2 <b>subject</b> 123äöü')

        # Click in the body field, to trigger the title update.
        find('.js-textarea').send_keys('trigger title')

        expect(page).to have_css('.js-objectTitle', text: 'TTTsome level 2 <b>subject</b> 123äöü')

        check_taskbar_tab(ticket.id, title: 'TTTsome level 2 <b>subject</b> 123äöü')

        expect(page).to have_css('.js-textarea', text: 'some other note')
      end

      expect(page).to have_css('.js-objectTitle', text: 'TTTsome level 2 <b>subject</b> 123äöü')
      expect(page).to have_css('.js-textarea', text: 'some note')

      check_taskbar_tab(ticket.id, title: 'TTTsome level 2 <b>subject</b> 123äöü', modified: true)

      # Refresh and check that modified flag is gone
      refresh
      check_taskbar_tab(ticket.id, title: 'TTTsome level 2 <b>subject</b> 123äöü', modified: false)
    end
  end

  context 'when working on multiple platforms', authenticated_as: :user do
    let(:ticket)       { create(:ticket) }
    let(:user)         { create(:agent, groups: [ticket.group]) }
    let(:another_user) { create(:agent, groups: [ticket.group]) }
    let(:key)          { "Ticket-#{ticket.id}" }
    let(:path)         { "ticket/zoom/#{ticket.id}" }

    let(:taskbar_mobile)  { create(:taskbar, user: user, app: :mobile, key: key) }
    let(:taskbar_desktop) { create(:taskbar, user: user, app: :desktop, key: key) }

    let(:another_taskbar_mobile)  { create(:taskbar, user: another_user, app: :mobile, key: key) }
    let(:another_taskbar_desktop) { create(:taskbar, user: another_user, app: :desktop, key: key) }

    context 'when looking on a ticket' do
      before do
        taskbar_desktop

        visit path
      end

      it 'does not show current user' do
        expect(page).not_to have_avatar(user)
      end
    end

    context 'when another user is looking on desktop' do
      before do
        another_taskbar_desktop
        taskbar_desktop

        visit path
      end

      it 'shows another user' do
        expect(page).to have_avatar(another_user).with_no_icon!
      end
    end

    context 'when another user is looking on mobile' do
      before do
        another_taskbar_mobile
        taskbar_desktop

        visit path
      end

      it 'shows another user' do
        expect(page).to have_avatar(another_user).with_icon(:mobile)
      end
    end

    context 'when another user is looking on mobile and desktop' do
      before do
        another_taskbar_mobile
        another_taskbar_desktop
        taskbar_desktop

        visit path
      end

      it 'shows another user' do
        expect(page).to have_avatar(another_user).with_no_icon!
      end
    end

    context 'when another user is editing on desktop' do
      before do
        another_taskbar_desktop.update!(state: { a: 1 })
        taskbar_desktop

        visit path
      end

      it 'shows another user' do
        expect(page).to have_avatar(another_user).with_icon(:pen).changed!
      end
    end

    context 'when another user is editing on mobile' do
      before do
        another_taskbar_mobile.update!(state: { a: 1 })
        taskbar_desktop

        visit path
      end

      it 'shows another user' do
        expect(page).to have_avatar(another_user).with_icon(:pen).changed!
      end
    end

    context 'when same user is looking on mobile too' do
      before do
        taskbar_mobile
        taskbar_desktop

        visit path
      end

      it 'shows same user' do
        expect(page).not_to have_avatar(user)
      end
    end

    context 'when same user is editing' do
      before do
        taskbar_desktop.update!(state: { a: 1 })

        visit path
      end

      it 'do not show same user' do
        expect(page).not_to have_avatar(user)
      end
    end

    context 'when same user is editing on mobile' do
      before do
        taskbar_mobile.update!(state: { a: 1 })
        taskbar_desktop

        visit path
      end

      it 'shows same user' do
        expect(page).to have_avatar(user).with_icon(:'mobile-edit').changed!
      end
    end
  end
end
