# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Keyboard Shortcuts', type: :system do
  context 'Navigation shortcut' do
    context 'for Dashboard' do
      before do
        visit 'ticket/view' # visit a different page first
        send_keys([*hot_keys, 'd'])
      end

      it 'shows Dashboard page' do
        expect(page).to have_title('Dashboard')
      end
    end

    context 'for Overviews' do
      before do
        visit 'dashboard' # visit a different page first
        send_keys([*hot_keys, 'o'])
      end

      it 'shows Overviews page' do
        expect(page).to have_title('My Assigned Tickets')
      end
    end

    context 'for Search' do
      before do
        visit '/'
        within :active_content do
          send_keys([*hot_keys, 's'])
        end
      end

      it 'changes focus to search input' do
        expect(page).to have_selector('#global-search:focus')
      end
    end

    context 'for Notifications' do
      let(:popover_notification_selector) { '.popover--notifications.js-notificationsContainer' }

      before do
        visit '/'
        send_keys([*hot_keys, 'a'])
      end

      it 'shows notifications popover' do
        within popover_notification_selector do
          expect(page).to have_text 'Notifications'
        end
      end

      it 'hides notifications popover when re-pressed' do
        within popover_notification_selector do
          send_keys([*hot_keys, 'a'])
        end

        expect(page).to have_no_selector popover_notification_selector
      end
    end

    context 'for New Ticket' do
      before do
        visit '/'
        send_keys([*hot_keys, 'n'])
      end

      it 'opens a new ticket page' do
        within :active_content do
          expect(page).to have_selector('.newTicket h1', text: 'New Ticket')
        end
      end
    end

    context 'for Logout' do
      before do
        visit '/'
        send_keys([*hot_keys, 'e'])
      end

      it 'goes to sign in page' do
        expect(page).to have_title('Sign in')
      end
    end

    context 'for list of shortcuts' do
      before do
        visit '/'
        send_keys([*hot_keys, 'h'])
      end

      it 'shows list of shortcuts' do
        in_modal do
          expect(page).to have_selector('h1', text: 'Keyboard Shortcuts')
        end
      end

      it 'hides list of shortcuts when re-pressed' do
        in_modal do
          send_keys([*hot_keys, 'h'])
        end
      end
    end

    context 'for Close current tab' do
      before do
        visit '/'

        send_keys([*hot_keys, 'n']) # opens a new ticket

        within :active_content, '.newTicket' do # make sure to close new ticket
          send_keys([*hot_keys, 'w'])
        end
      end

      it 'closes current tab' do
        within :active_content do
          expect(page).to have_no_selector('.newTicket')
        end
      end
    end

    context 'with tab as shortcut' do
      before do
        # The current hotkey for the next/previous tab is not working on linux/windows, skip for now.
        skip('current hotkey for the next/previous tab is not working on linux/windows')

        visit 'ticket/create'

        within :active_content, '.newTicket' do
          find('[data-type="phone-in"]').click
          visit 'ticket/create'
        end

        within :active_content, '.newTicket' do
          find('[data-type="phone-out"]').click
          visit 'ticket/create'
        end

        within :active_content, '.newTicket' do
          find('[data-type="email-out"]').click
          send_keys([*hot_keys, *tab]) # open next/prev tab
        end
      end

      context 'shows the next tab' do
        let(:tab) { [:tab] }

        it 'show the next tab' do
          within :active_content, 'form.ticket-create' do
            expect(page).to have_title 'Inbound Call'
          end
        end
      end

      context 'shows the previous tab' do
        let(:tab) { %i[shift tab] }

        it 'shows the previous tab' do
          within :active_content, 'form.ticket-create' do
            expect(page).to have_title 'Outbound Call'
          end
        end
      end
    end
  end
end
