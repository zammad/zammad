# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Keyboard shortcuts', app: :desktop_view, type: :playwright do
  let(:group)  { create(:group) }
  let(:agent)  { create(:agent, groups: [group]) }
  let(:ticket) { create(:ticket, group:, title: 'First ticket') }

  # A page without a text field focused on load, so key presses reach the shortcuts.
  let(:start_page) { '/personal-setting/devices' }

  # The layout registers the shortcuts once it is mounted, which is after the app has loaded.
  def open_start_page
    open_desktop(start_page)
    expect(main_sidebar).to be_visible
  end

  def press(keys)
    page.keyboard.press(keys)
  end

  def open_ticket_for_shortcuts(ticket)
    open_desktop_ticket(ticket)
    page.get_by_role('article').first.wait_for(state: 'visible')
    page.evaluate('() => document.activeElement.blur()')
  end

  # The old desktop view writes the switch, JSON-encoded and per browser.
  def turn_shortcuts_off
    page.evaluate("() => localStorage.setItem('keyboardShortcuts', 'false')")
  end

  def turn_shortcuts_on
    page.evaluate("() => localStorage.removeItem('keyboardShortcuts')")
  end

  # Registered after the shortcut listener, so it sees whether a shortcut took the key. A check
  #   of the URL alone would pass before a lazily loaded route is reached.
  def record_handled_keys
    page.evaluate(<<~JS)
      () => {
        window.handledKeys = []
        window.addEventListener('keydown', (event) => window.handledKeys.push(event.defaultPrevented))
      }
    JS
  end

  def handled_keys
    page.evaluate('() => window.handledKeys')
  end

  def cheat_sheet
    page.get_by_role('dialog', name: 'Keyboard shortcuts', exact: true)
  end

  def expect_cheat_sheet_open
    expect(cheat_sheet.get_by_role('heading', name: 'Navigation', exact: true)).to be_visible
  end

  context 'with an agent', authenticated_as: :agent do
    context 'with the shortcut switch of the old desktop view' do
      before { open_start_page }

      it 'does nothing while shortcuts are turned off, until they are turned on again' do
        turn_shortcuts_off
        reload_page

        press('o')
        expect(page).to have_url(%r{/desktop/personal-setting})

        turn_shortcuts_on
        reload_page

        press('o')
        expect(page).to have_url(%r{/desktop/tickets/view})
      end

      it 'picks up a change made in another tab without a reload' do
        other_tab = open_tab
        on_tab(other_tab) do
          open_start_page
          turn_shortcuts_off
        end

        press('o')
        expect(page).to have_url(%r{/desktop/personal-setting})

        on_tab(other_tab) { turn_shortcuts_on }

        press('o')
        expect(page).to have_url(%r{/desktop/tickets/view})
      end
    end

    context 'with the cheat sheet' do
      before { open_start_page }

      def shortcut_switch
        cheat_sheet.get_by_role('switch', name: 'Enable keyboard shortcuts', exact: true)
      end

      def open_cheat_sheet
        main_sidebar.get_by_role('button', name: agent.fullname, exact: true).click
        page.get_by_role('button', name: 'Keyboard shortcuts', exact: true).click

        expect_cheat_sheet_open
      end

      it 'turns the shortcuts off from the avatar menu, also after a reload' do
        open_cheat_sheet
        expect(shortcut_switch).to be_checked

        shortcut_switch.click
        expect(shortcut_switch).not_to be_checked
        expect(cheat_sheet.get_by_text('Dashboard', exact: true)).to be_visible

        # The form field hands over its value after a short delay, the switch is unchecked before that.
        page.wait_for_function("() => localStorage.getItem('keyboardShortcuts') === 'false'")

        press('Escape')
        expect(cheat_sheet).to be_hidden

        record_handled_keys
        press('o')

        expect(handled_keys).to eq([false])
        expect(page).to have_url(%r{/desktop/personal-setting})

        reload_page
        open_cheat_sheet

        expect(shortcut_switch).not_to be_checked
      end

      it 'opens with ? and closes with a second ? or with Escape' do
        press('?')
        expect_cheat_sheet_open

        press('?')
        expect(cheat_sheet).to be_hidden

        press('?')
        expect_cheat_sheet_open

        press('Escape')
        expect(cheat_sheet).to be_hidden
      end

      it 'leaves ? to the quick search field' do
        search_field = main_sidebar.get_by_role('searchbox', name: 'Search…')
        search_field.click

        press('?')

        expect(search_field).to have_value('?')
        expect(cheat_sheet).to be_hidden
      end

      it 'stays open while a listed shortcut navigates' do
        open_cheat_sheet

        press('o')

        expect(page).to have_url(%r{/desktop/tickets/view})
        expect_cheat_sheet_open
      end

      it 'closes when the listed shortcut signs out' do
        open_cheat_sheet

        press('Shift+L')

        expect(page).to have_url(%r{/desktop/login})
        expect(cheat_sheet).to be_hidden
      end
    end

    context 'with navigation shortcuts' do
      before { open_start_page }

      it 'goes to the dashboard' do
        press('h')
        expect(page).to have_url(%r{/desktop/dashboard})
      end

      it 'does nothing with h while the dashboard is turned off' do
        Setting.set('dashboard', false)
        open_start_page

        record_handled_keys
        press('h')

        expect(handled_keys).to eq([false])
        expect(page).to have_url(%r{/desktop/personal-setting})
      end

      it 'goes to the overviews' do
        press('o')
        expect(page).to have_url(%r{/desktop/tickets/view})
      end

      it 'opens a new ticket' do
        press('n')
        expect(page).to have_url(%r{/desktop/tickets/create/})
      end

      it 'focuses the quick search' do
        press('s')
        expect(main_sidebar.get_by_role('searchbox', name: 'Search…')).to be_focused
      end

      it 'toggles the notifications' do
        press('a')
        expect(page.get_by_role('heading', name: 'Notifications', exact: true)).to be_visible

        press('a')
        expect(page.get_by_role('heading', name: 'Notifications', exact: true)).to be_hidden
      end

      it 'toggles the user menu' do
        press('u')
        expect(page.get_by_role('link', name: 'Sign out', exact: true)).to be_visible

        press('u')
        expect(page.get_by_role('link', name: 'Sign out', exact: true)).to be_hidden
      end

      it 'signs out' do
        press('Shift+L')
        expect(page).to have_url(%r{/desktop/login})
      end

      it 'leaves a modifier-less key to a focused text field' do
        press('s')
        press('o')

        expect(main_sidebar.get_by_role('searchbox', name: 'Search…')).to have_value('o')
        expect(page).to have_url(%r{/desktop/personal-setting})
      end
    end

    context 'with an empty overview' do
      before { open_start_page }

      it 'moves over the overviews with the arrow keys right away' do
        press('o')
        expect(page).to have_url(%r{/desktop/tickets/view/my_assigned$})
        expect(page.get_by_role('heading', level: 2, name: 'Empty overview')).to be_visible

        active_overview = page.get_by_role('navigation', name: 'Overview navigation list')
          .get_by_role('link', name: %r{^My Assigned Tickets})

        press('ArrowDown')
        expect(active_overview).to be_focused

        press('ArrowDown')
        expect(active_overview).not_to be_focused

        press('Enter')
        expect(page).to have_url(%r{/desktop/tickets/view/(?!my_assigned$)})
      end
    end

    context 'with list navigation' do
      let(:first_ticket)  { create(:ticket, group:, owner: agent, title: 'First assigned ticket') }
      let(:second_ticket) { create(:ticket, group:, owner: agent, title: 'Second assigned ticket') }

      # The row's ticket, whichever order the list sorts the tickets in.
      def ticket_route(row)
        ticket = [first_ticket, second_ticket].find { |candidate| row.text_content.include?(candidate.title) }

        %r{/desktop/tickets/#{ticket.id}$}
      end

      before do
        first_ticket
        second_ticket
      end

      it 'walks the overview list and its sidebar with the arrow keys and opens a ticket' do
        open_desktop('/tickets/view/my_assigned')

        rows = table_rows('Overview: My Assigned Tickets')
        expect(rows).to have_count(2)

        page.evaluate('() => document.activeElement.blur()')

        press('ArrowDown')
        expect(rows.nth(0)).to be_focused

        press('ArrowDown')
        expect(rows.nth(1)).to be_focused

        press('ArrowLeft')
        overview_link = page.get_by_role('navigation', name: 'Overview navigation list')
          .get_by_role('link', name: %r{^My Assigned Tickets})
        expect(overview_link).to be_focused

        press('ArrowRight')
        expect(rows.nth(1)).to be_focused

        route = ticket_route(rows.nth(1))
        press('Enter')
        expect(page).to have_url(route)
      end

      it 'goes down from the search field to the results and back up', searchindex: true do
        searchindex_model_reload([Ticket])

        open_desktop('/search/assigned')

        rows = table_rows('Search result for: Ticket')
        expect(rows).to have_count(2)

        search_field = main_content.get_by_role('searchbox', name: 'Search…')
        search_field.focus

        press('ArrowDown')
        expect(rows.nth(0)).to be_focused

        press('ArrowUp')
        expect(search_field).to be_focused

        press('ArrowDown')
        route = ticket_route(rows.nth(0))
        press('Enter')
        expect(page).to have_url(route)
      end
    end

    context 'with the form submit shortcut' do
      let(:customer) { create(:customer) }

      before do
        customer
        open_desktop('/ticket/create')
        wait_for_form_to_settle('ticket-create')
      end

      it 'creates a ticket with ctrl+enter from the editor' do
        fill_field('Title', 'Created from the keyboard')
        search_for_option('Customer', customer.email, option: customer.fullname)
        type_in_editor('Text', 'First line', :enter, 'Second line')

        press('Control+Enter')

        expect(notification('Ticket has been created successfully')).to be_visible
        expect(Ticket.last).to have_attributes(title: 'Created from the keyboard', group:, customer:)
        expect(Ticket.last.articles.first.body).to include('First line').and include('Second line')
      end
    end

    context 'with the appearance shortcut' do
      let(:theme) { page.locator('html') }

      before do
        page.emulate_media(colorScheme: 'light')
        open_start_page
      end

      it 'switches to the opposite of the system and back to following it' do
        expect(theme).to have_attribute('data-theme', 'light')

        press('d')

        wait_for_mutation('userCurrentAppearance')
        expect(theme).to have_attribute('data-theme', 'dark')
        expect(agent.reload.preferences['theme']).to eq('dark')

        press('d')

        wait_for_mutation('userCurrentAppearance', number: 2)
        expect(theme).to have_attribute('data-theme', 'light')
        expect(agent.reload.preferences['theme']).to eq('auto')
      end
    end

    context 'with the shortcuts of the ticket detail view' do
      before do
        create(:ticket_article, :inbound_email, ticket:)

        open_ticket_for_shortcuts(ticket)
      end

      # Checked while the article is internal.
      def visibility_switch
        main_content.get_by_role('switch', name: 'Visibility', exact: true)
      end

      it 'opens the note box with x and switches the note between internal and public with i' do
        press('x')

        wait_for_editor_ready(editor('Text'))

        # Whether a new note starts internal is up to the form, the shortcut flips what it finds.
        internal = visibility_switch.get_attribute('aria-checked')
        flipped = internal == 'true' ? 'false' : 'true'

        # The note box takes the focus, where the key is left to the editor.
        page.evaluate('() => document.activeElement.blur()')
        press('i')
        expect(visibility_switch).to have_attribute('aria-checked', value: flipped)

        press('i')
        expect(visibility_switch).to have_attribute('aria-checked', value: internal)
      end

      it 'replies to the last article with r' do
        press('r')

        expect(editor('Text')).to be_visible
        expect(visibility_switch).not_to be_checked
      end
    end

    context 'with the close shortcut' do
      let(:default_close_state) { Ticket::State.find_by(name: 'closed') }

      before do
        create(:ticket_article, ticket:)
        default_close_state.update!(default_close: true)

        open_ticket_for_shortcuts(ticket)
      end

      it 'updates the ticket as closed' do
        press('Shift+C')

        expect(notification('Ticket updated successfully.')).to be_visible
        expect(ticket.reload.state).to eq(default_close_state)
      end

      context 'when the default close state is a pending one' do
        let(:default_close_state) { Ticket::State.find_by(name: 'pending close') }

        it 'fills in the pending time of three days the core workflow asks for' do
          press('Shift+C')

          expect(notification('Ticket updated successfully.')).to be_visible
          expect(ticket.reload).to have_attributes(state: default_close_state, pending_time: be_within(1.hour).of(3.days.from_now))
        end
      end
    end

    context 'with taskbar tabs' do
      let(:second_ticket) { create(:ticket, group:, title: 'Second ticket') }

      before do
        create(:taskbar, :with_ticket, ticket:, user_id: agent.id, app: 'desktop', prio: 1)
        create(:taskbar, :with_ticket, ticket: second_ticket, user_id: agent.id, app: 'desktop', prio: 2)

        open_start_page

        # The tabs load after the layout, and a tab shortcut without tabs does nothing.
        main_sidebar.get_by_role('treeitem').filter(hasText: 'Second ticket').wait_for(state: 'visible')
      end

      it 'activates the next and previous tab, wrapping around at either end' do
        press('Shift+ArrowRight')
        expect(page).to have_url(%r{/desktop/tickets/#{ticket.id}$})

        page.evaluate('() => document.activeElement.blur()')
        press('Shift+ArrowRight')
        expect(page).to have_url(%r{/desktop/tickets/#{second_ticket.id}$})

        page.evaluate('() => document.activeElement.blur()')
        press('Shift+ArrowRight')
        expect(page).to have_url(%r{/desktop/tickets/#{ticket.id}$})

        page.evaluate('() => document.activeElement.blur()')
        press('Shift+ArrowLeft')
        expect(page).to have_url(%r{/desktop/tickets/#{second_ticket.id}$})
      end

      it 'focuses the search field only when the search comes from the quick search', searchindex: true do
        searchindex_model_reload([Ticket])

        search_from_quick_search = lambda do |term|
          press('s')
          main_sidebar.get_by_role('searchbox', name: 'Search…').fill(term)
          press('Enter')
          expect(page).to have_url(%r{/desktop/search/#{term}})
        end

        search_field = main_content.get_by_role('searchbox', name: 'Search…')

        search_from_quick_search.call('ticket')
        expect(search_field).to be_focused

        page.evaluate('() => document.activeElement.blur()')
        press('Shift+ArrowLeft')
        expect(page).not_to have_url(%r{/desktop/search})

        # Back in the browser's history is no search from the quick search.
        page.go_back
        expect(page).to have_url(%r{/desktop/search/ticket})
        expect(search_field).not_to be_focused

        press('Shift+ArrowRight')
        expect(page).not_to have_url(%r{/desktop/search})

        page.evaluate('() => document.activeElement.blur()')
        press('Shift+ArrowLeft')
        expect(page).to have_url(%r{/desktop/search/ticket})
        expect(search_field).not_to be_focused

        press('Shift+ArrowRight')
        expect(page).not_to have_url(%r{/desktop/search})

        # A search from the quick search while the search view is kept in the background.
        search_from_quick_search.call('first')
        expect(search_field).to be_focused
      end

      it 'closes the active tab' do
        open_desktop_ticket(ticket)
        page.evaluate('() => document.activeElement.blur()')

        press('Shift+W')

        expect(main_sidebar.get_by_role('treeitem').filter(hasText: 'First ticket')).to be_hidden
        expect(main_sidebar.get_by_role('treeitem').filter(hasText: 'Second ticket')).to be_visible
      end

      it 'asks before closing a tab with unsaved changes' do
        open_desktop('/tickets/create')
        wait_for_form_to_settle('ticket-create')
        fill_field('Title', 'Unsaved ticket title')
        page.evaluate('() => document.activeElement.blur()')

        press('Shift+W')

        expect(page.get_by_role('dialog', name: 'Unsaved changes')).to be_visible
      end
    end
  end

  context 'with a customer', authenticated_as: :customer do
    let(:customer) { create(:customer) }

    before { open_start_page }

    it 'reaches the overviews, a new ticket, the search and the user menu' do
      press('o')
      expect(page).to have_url(%r{/desktop/tickets/view})

      press('n')
      expect(page).to have_url(%r{/desktop/tickets/create/})

      page.evaluate('() => document.activeElement.blur()')
      press('s')
      expect(main_sidebar.get_by_role('searchbox', name: 'Search…')).to be_focused

      press('Escape')
      page.evaluate('() => document.activeElement.blur()')
      press('u')
      expect(page.get_by_role('link', name: 'Sign out', exact: true)).to be_visible
    end

    it 'opens the cheat sheet with ? and lists only what they can use' do
      press('?')

      expect_cheat_sheet_open
      expect(cheat_sheet.get_by_text('Overviews', exact: true)).to be_visible
      expect(cheat_sheet.get_by_text('Toggle dark mode', exact: true)).to be_visible
      expect(cheat_sheet.get_by_text('Dashboard', exact: true)).to be_hidden
      expect(cheat_sheet.get_by_text('Notifications', exact: true)).to be_hidden
      expect(cheat_sheet.get_by_text('Open note box', exact: true)).to be_hidden
    end

    it 'has no notifications to toggle' do
      press('a')

      # Key presses are handled in order: once the user menu is open, `a` has been handled too.
      press('u')
      expect(page.get_by_role('link', name: 'Sign out', exact: true)).to be_visible

      expect(page.get_by_role('heading', name: 'Notifications', exact: true)).to be_hidden
    end

    context 'with a ticket of their own' do
      let(:ticket) { create(:ticket, customer:) }

      before do
        create(:ticket_article, :inbound_email, ticket:)

        open_ticket_for_shortcuts(ticket)
      end

      it 'leaves x, r and i alone, which belong to agents' do
        record_handled_keys

        press('x')
        press('r')

        expect(handled_keys).to eq([false, false])
        expect(page.get_by_role('textbox', name: 'Text')).to be_hidden

        main_content.get_by_role('button', name: 'Add reply', exact: true).click
        expect(editor('Text')).to be_visible

        page.evaluate('() => document.activeElement.blur()')
        press('i')

        expect(handled_keys).to eq([false, false, false])
      end
    end
  end
end
