# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket > Update > Simultaneously with two different user', type: :system do
  let(:group)  { Group.find_by(name: 'Users') }
  let(:ticket) { create(:ticket, group: group) }
  let(:agent)  { User.find_by(login: 'agent1@example.com') }

  def check_avatar(text, changed: true)
    changed_class = changed ? 'changed' : 'not-changed'

    within(:active_content) do
      expect(page).to have_css(".js-attributeBar .js-avatar .avatar--#{changed_class}", text: text)
    end
  end

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
      check_avatar('AT', changed: false)

      using_session(:second_browser) do
        check_avatar('TA', changed: false)
      end
    end

    it 'check changes from the first user and added changes from the second user' do
      within(:active_content) do
        find('.js-textarea').send_keys('some note')

        expect(page).to have_css('.js-reset')
      end

      check_avatar('AT', changed: false)

      using_session(:second_browser) do
        check_avatar('TA', changed: true)

        within(:active_content) do
          find('.js-textarea').send_keys('some other note')

          expect(page).to have_css('.js-reset')
        end
      end

      check_avatar('AT', changed: true)

      using_session(:second_browser) do
        within(:active_content) do
          click '.js-attributeBar .js-submit'

          expect(page).to have_no_css('.js-reset')
          expect(page).to have_css('.article-content', text: 'some other note')
        end

        check_avatar('TA', changed: true)
      end

      check_avatar('AT', changed: false)
      check_taskbar_tab(ticket.id, title: ticket.title, modified: true)

      within(:active_content) do
        expect(page).to have_css('.article-content', text: 'some other note')

        click '.js-attributeBar .js-submit'

        expect(page).to have_no_css('.js-reset')
        expect(page).to have_css('.article-content', text: 'some note')
      end

      using_session(:second_browser) do
        check_avatar('TA', changed: false)

        expect(page).to have_css('.article-content', text: 'some note')
        check_taskbar_tab(ticket.id, title: ticket.title, modified: true)
      end

      # Reload browsers and check if state is correct.
      refresh

      using_session(:second_browser) do
        refresh

        check_avatar('TA', changed: false)
        expect(page).to have_no_css('.js-reset')
      end

      check_avatar('AT', changed: false)
      expect(page).to have_no_css('.js-reset')
    end

    it 'check refresh for unsaved changes and reset after refresh' do
      using_session(:second_browser) do
        within(:active_content) do
          find('.js-textarea').send_keys('some other note')

          expect(page).to have_css('.js-reset')
        end

        check_avatar('TA', changed: false)

        # We need to wait for the auto save feature.
        wait.until do
          Taskbar.find_by(key: "Ticket-#{ticket.id}", user_id: agent.id).state_changed?
        end

        refresh
      end

      check_avatar('AT', changed: true)

      using_session(:second_browser) do
        refresh

        within(:active_content) do
          click '.js-reset'
          expect(page).to have_css('.js-textarea', text: '')
        end
      end

      check_avatar('AT', changed: false)
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
end
