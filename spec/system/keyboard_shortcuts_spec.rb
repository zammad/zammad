# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Keyboard Shortcuts', type: :system do
  context 'Navigation shortcut' do
    context 'for Dashboard' do
      before do
        visit 'ticket/view' # visit a different page first
        send_keys(['h'])
      end

      it 'shows Dashboard page' do
        expect(page).to have_title('Dashboard')
      end
    end

    context 'for Overviews' do
      before do
        visit 'dashboard' # visit a different page first
        send_keys(['o'])
      end

      it 'shows Overviews page' do
        expect(page).to have_title('My Assigned Tickets')
      end
    end

    context 'for Search' do
      before do
        visit '/'
        within :active_content do
          send_keys(['s'])
        end
      end

      it 'changes focus to search input' do
        expect(page).to have_css('#global-search:focus')
      end
    end

    context 'for Notifications' do
      let(:popover_notification_selector) { '.popover--notifications.js-notificationsContainer' }

      before do
        visit '/'
        send_keys(['a'])
      end

      it 'shows notifications popover' do
        within popover_notification_selector do
          expect(page).to have_text 'Notifications'
        end
      end

      it 'hides notifications popover when re-pressed' do
        within popover_notification_selector do
          send_keys(['a'])
        end

        expect(page).to have_no_selector popover_notification_selector
      end
    end

    context 'for New Ticket' do
      before do
        visit '/'
        send_keys(['n'])
      end

      it 'opens a new ticket page' do
        within :active_content do
          expect(page).to have_css('.newTicket h1', text: 'New Ticket')
        end
      end
    end

    context 'for list of shortcuts' do
      before do
        visit '/'
        send_keys(['?'])
      end

      it 'shows list of shortcuts' do
        in_modal do
          expect(page).to have_css('h1', text: 'Keyboard Shortcuts')
        end
      end

      it 'hides list of shortcuts when re-pressed' do
        in_modal do
          send_keys(['?'])
        end
      end
    end

    context 'for Logout' do
      before do
        visit '/'
        within :active_content, '.dashboard' do
          send_keys([:shift, 'l'])
        end
      end

      it 'goes to sign in page' do
        expect(page).to have_title('Sign in')
      end
    end

    context 'for Close current tab' do
      before do
        visit '/'

        send_keys(['n']) # opens a new ticket

        within :active_content, '.newTicket' do # make sure to close new ticket
          send_keys([:shift, 'w'])
        end
      end

      it 'closes current tab' do
        within :active_content do
          expect(page).to have_no_selector('.newTicket')
        end
      end
    end

    context 'for tabs and shortcuts' do
      before do
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
        end
      end

      context 'shows the next tab' do
        it 'show the next tab' do
          await_empty_ajax_queue
          send_keys(%i[shift arrow_right])

          within :active_content, 'form.ticket-create' do
            expect(page).to have_title 'Inbound Call'
          end
        end
      end

      context 'shows the previous tab' do
        it 'shows the previous tab' do
          await_empty_ajax_queue
          send_keys(%i[shift arrow_left])

          within :active_content, 'form.ticket-create' do
            expect(page).to have_title 'Outbound Call'
          end
        end
      end
    end
  end

  context 'Tickets shortcut' do
    context 'for ticket edit' do
      before do
        visit "#ticket/zoom/#{Ticket.first.id}"
      end

      it 'add internal note and submit' do
        send_keys(['x'])
        send_keys(['some text'])

        within :active_content do
          expect(page).to have_css('.article-new .js-textarea', text: 'some text')
        end

        within :active_content do
          expect(page).to have_css('.is-internal')
        end

        send_keys(%i[shift return])

        within :active_content do
          expect(page).to have_css('.article-content', text: 'some text')
        end

        within :active_content do
          expect(page).to have_css('.article-new .js-textarea', text: '')
        end
      end

      it 'add public note and submit' do
        send_keys(['i'])
        send_keys(['x'])
        send_keys(['some text'])

        within :active_content do
          expect(page).to have_css('.article-new .js-textarea', text: 'some text')
        end

        within :active_content do
          expect(page).to have_no_selector('.is-internal')
        end

        send_keys(%i[shift return])

        within :active_content do
          expect(page).to have_css('.article-content', text: 'some text')
        end

        within :active_content do
          expect(page).to have_css('.article-new .js-textarea', text: '')
        end
      end
    end
  end

  context 'Translations shortcut' do
    context 'for inline translations' do
      before do
        visit '/'
      end

      it 'enables translations' do
        within :active_content do
          expect(page).to have_no_selector('.stat-title span.translation')
        end
        expect(page).to have_no_selector('#navigation [href="#dashboard"] span.translation')

        send_keys(['t'])

        within :active_content do
          expect(page).to have_css('.stat-title span.translation')
        end
        expect(page).to have_css('#navigation [href="#dashboard"] span.translation')
      end

      it 'does not enable translations with a modifier (#5312)' do
        within :active_content do
          expect(page).to have_no_selector('.stat-title span.translation')
        end
        expect(page).to have_no_selector('#navigation [href="#dashboard"] span.translation')

        send_keys([:control, 't'])

        within :active_content do
          expect(page).to have_no_css('.stat-title span.translation')
        end

        expect(page).to have_no_css('#navigation [href="#dashboard"] span.translation')
      end
    end
  end

  context 'when toggling switches' do
    before do
      visit 'dashboard' # visit a different page first
      send_keys(['?'])
    end

    context 'when disabling keyboard shortcuts' do
      it 'disables keyboard shortcuts' do
        in_modal do
          uncheck 'Keyboard Shortcuts Enabled', allow_label_click: true
          click '.js-close'
        end

        send_keys(['o'])

        expect(page).to have_title('Dashboard')
      end
    end

    context 'when enabling keyboard shortcuts' do
      it 'enables keyboard shortcuts' do
        in_modal do
          uncheck 'Keyboard Shortcuts Enabled', allow_label_click: true
          check 'Keyboard Shortcuts Enabled', allow_label_click: true
          click '.js-close'
        end

        send_keys(['o'])

        expect(page).to have_title('My Assigned Tickets')
      end
    end

    context 'when switching to old shortcut layout' do
      it 'uses old shortcut layout' do
        in_modal do
          click_on 'Switch back to old layout'
          click '.js-close'
        end

        send_keys(['o'])

        expect(page).to have_title('Dashboard')

        send_keys([*hot_keys, 'o'])

        expect(page).to have_title('My Assigned Tickets')
      end
    end

    context 'when switching to new shortcut layout' do
      it 'uses new shortcut layout' do
        in_modal do
          click_on 'Switch back to old layout'
          click_on 'Switch to new layout'
          click '.js-close'
        end

        send_keys([*hot_keys, 'o'])

        expect(page).to have_title('Dashboard')

        send_keys(['o'])

        expect(page).to have_title('My Assigned Tickets')
      end
    end
  end
end
