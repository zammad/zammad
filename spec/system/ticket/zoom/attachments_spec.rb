# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Attachments', type: :system do
  context 'when ticket has an attachment' do

    let(:group)           { Group.find_by(name: 'Users') }
    let(:ticket)          { create(:ticket, group: group) }
    let(:article)         { create(:ticket_article, ticket: ticket) }
    let(:attachment_name) { 'some_file.txt' }

    before do
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'some content',
             filename:    attachment_name,
             preferences: {
               'Content-Type' => 'text/plain',
             })
    end

    describe 'article was already forwarded once' do
      before do
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          find('a[data-type=emailForward]').click

          click('.js-reset')
          wait.until_disappears { find('.js-reset', wait: 0) }
        end
      end

      it 'adds attachments when forwarding multiple times' do

        within(:active_content) do
          find('a[data-type=emailForward]').click
        end

        within('.js-writeArea') do
          expect(page).to have_text attachment_name
        end
      end
    end
  end

  context 'when ticket has a calendar attachment' do
    let(:group) { Group.find_by(name: 'Users') }
    let(:store_file_content_name) do
      Rails.root.join('spec/fixtures/files/calendar/basic.ics').read
    end
    let(:store_file_name) { 'basic.ics' }
    let(:expected_event) do
      {
        'title'       => 'Test Summary',
        'location'    => 'https://us.zoom.us/j/example?pwd=test',
        'attendees'   => ['M.bob@example.com', 'J.doe@example.com'],
        'organizer'   => 'f.sample@example.com',
        'description' => 'Test description'
      }
    end
    let(:ticket)          { create(:ticket, group: group) }
    let(:article)         { create(:ticket_article, ticket: ticket) }

    before do
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        store_file_content_name,
             filename:    store_file_name,
             preferences: {
               'Content-Type' => 'text/calendar',
             })

      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'has an attached calendar file' do
      within :active_ticket_article, article do
        within '.attachment.file-calendar' do
          expect(page).to have_text(store_file_name)
        end
      end
    end

    it 'shows a preview button for the calendar file' do
      within :active_ticket_article, article do
        within '.attachment.file-calendar' do
          expect(page).to have_button('Preview')
        end
      end
    end

    context 'when calendar preview button is clicked' do
      before do
        within :active_ticket_article, article do
          within '.attachment.file-calendar' do
            click_on 'Preview'
          end
        end
      end

      it 'shows calender data in the model' do
        in_modal do
          expect(page).to have_text expected_event['title']
          expect(page).to have_text expected_event['location']
          expected_event['attendees'].each { |attendee| expect(page).to have_text attendee }
          expect(page).to have_text expected_event['organizer']
          expect(page).to have_text expected_event['description']
        end
        click '.js-cancel'
      end
    end
  end

  # https://github.com/zammad/zammad/issues/2942
  describe 'attachments are lost in specific conditions' do
    let(:ticket) { create(:ticket, group: Group.first) }

    it 'attachment is retained when forwarding a fresh article' do
      ensure_websocket do
        visit "ticket/zoom/#{ticket.id}"
      end

      # add an article, forcing reset of form_id

      # click in the upper most upper left corner of the article create textbox
      # (that works for both Firefox and Chrome)
      # to avoid clicking on attachment upload
      find('.js-writeArea').click(x: 5, y: 5)

      # wait for propagateOpenTextarea to be completed
      find('.attachmentPlaceholder-label').in_fixed_position
      expect(page).to have_no_css('.attachmentPlaceholder-hint')

      # write article content
      find('.articleNewEdit-body').send_keys('Some reply')
      click '.js-submit'

      # wait for article to be added to the page
      expect(page).to have_css('.ticket-article-item', count: 1)

      # create a on-the-fly article with attachment that will get pushed to open browser
      article1 = create(:ticket_article, ticket: ticket)
      create(:store,
             object:      'Ticket::Article',
             o_id:        article1.id,
             data:        'some content',
             filename:    'some_file.txt',
             preferences: {
               'Content-Type' => 'text/plain',
             })

      # wait for article to be added to the page
      expect(page).to have_css('.ticket-article-item', count: 2)

      # click on forward of created article
      within :active_ticket_article, article1 do
        find('a[data-type=emailForward]').click
      end

      # wait for propagateOpenTextarea to be completed
      find('.attachmentPlaceholder-label').in_fixed_position
      expect(page).to have_no_css('.attachmentPlaceholder-hint')

      # fill forward information and create article
      fill_in 'To', with: 'forward@example.org'
      find('.articleNewEdit-body').send_keys('Forwarding with the attachment')
      click '.js-submit'

      # wait for article to be added to the page
      expect(page).to have_css('.ticket-article-item', count: 3)

      # check if attachment was forwarded successfully
      within :active_ticket_article, ticket.reload.articles.last do
        within '.attachments--list' do
          expect(page).to have_text('some_file.txt')
        end
      end
    end
  end

  describe 'Notes on existing ticks are discarded by editing profile settings #3088' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    def upload_and_set_text
      page.find('.js-textarea').send_keys("Hello\nThis\nis\nimportant!\nyo\nhoho\ntest test test test")
      page.find('input#fileUpload_1', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
      expect(page).to have_text('mail001.box')
      wait_for_upload_present
    end

    def wait_for_upload_present
      wait.until { Taskbar.find_by(key: "Ticket-#{ticket.id}").attributes_with_association_ids['attachments'].present? }
    end

    def wait_for_upload_blank
      wait.until { Taskbar.find_by(key: "Ticket-#{ticket.id}").attributes_with_association_ids['attachments'].blank? }
    end

    def switch_language_german
      visit '#profile/language'
      # Suppress the modal dialog that invites to contributions for translations that are < 90% as this breaks the tests for de-de.
      page.evaluate_script "App.LocalStorage.set('translation_support_no', true, App.Session.get('id'))"
      page.find('.js-input').click
      page.find('.js-input').set('Deutsch')
      page.find('.js-input').send_keys(:enter)
      click_on 'Submit'

      visit "#ticket/zoom/#{ticket.id}"
      expect(page).to have_text(Translation.translate('de-de', 'select attachment…'))
    end

    def expect_upload_and_text
      expect(page.find('.article-new')).to have_text('mail001.box')
      expect(page.find('.article-new')).to have_text("Hello\nThis\nis\nimportant!\nyo\nhoho\ntest test test test")
    end

    def expect_no_upload_and_text
      expect(page.find('.article-new')).to have_no_text('mail001.box')
      expect(page.find('.article-new')).to have_no_text("Hello\nThis\nis\nimportant!\nyo\nhoho\ntest test test test")
    end

    it 'does show up the attachments after a reload of the page' do
      upload_and_set_text
      expect_upload_and_text
      refresh
      expect_upload_and_text
    end

    it 'does show up the attachments after updating language (ui:rerender event)' do
      upload_and_set_text
      expect_upload_and_text
      switch_language_german
      expect_upload_and_text
    end

    it 'does remove attachments and text on reset' do
      upload_and_set_text
      expect_upload_and_text

      page.find('.js-reset').click
      wait_for_upload_blank
      expect_no_upload_and_text
      refresh
      expect_no_upload_and_text
    end

    context 'when rerendering (#3831)' do
      def rerender
        page.evaluate_script("App.Event.trigger('ui:rerender')")
      end

      it 'does keep attachments after rerender' do
        upload_and_set_text
        expect_upload_and_text
        rerender
        expect_upload_and_text
      end

      it 'does not readd the attachments after reset' do
        upload_and_set_text
        expect_upload_and_text

        page.find('.js-reset').click
        wait_for_upload_blank
        expect_no_upload_and_text
        rerender
        expect_no_upload_and_text
      end

      it 'does not readd the attachments after submit' do
        upload_and_set_text
        expect_upload_and_text

        page.find('.js-submit').click
        wait_for_upload_blank
        expect_no_upload_and_text
        rerender
        expect_no_upload_and_text
      end

      it 'does not show the ticket as changed after the upload removal' do
        page.find('input#fileUpload_1[data-initialized="true"]', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
        await_empty_ajax_queue
        expect(page.find('.article-new')).to have_text('mail001.box')
        wait_for_upload_present
        begin
          page.evaluate_script("$('div.attachment-delete.js-delete:last').trigger('click')") # not interactable
        rescue # Lint/SuppressedException
          # because its not interactable it also
          # returns this weird exception for the jquery
          # even tho it worked fine
        end
        expect(page).to have_no_css('.js-reset')
      end
    end
  end
end
