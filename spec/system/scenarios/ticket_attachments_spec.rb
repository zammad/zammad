# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/agent_ticket_attachment_test.rb as end-to-end scenarios:
#   the "attachment mentioned but missing" confirmation in create and zoom, multi file
#   upload display, per-article attachment isolation, the missing-body warning dialog
#   and the disabled submit button during a running upload. The customer/organization
#   live sync scenarios of the original file live in ticket_customer_live_sync_spec.rb.
RSpec.describe 'Scenario > Ticket attachments', authenticated_as: :authenticate, type: :system do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:customer) { create(:customer) }
  let(:upload1)  { Rails.root.join('test/data/upload/upload1.txt') }
  let(:upload2)  { Rails.root.join('test/data/upload/upload2.jpg') }

  def authenticate
    customer

    agent
  end

  describe 'in the ticket create mask' do
    it 'warns about a mentioned but missing attachment and shows the uploads on the ticket' do
      visit 'ticket/create'

      within(:active_content) do
        find('[name=customer_id_completion]').fill_in with: customer.email

        expect(page).to have_css('.recipientList-entry.js-object')
        first('.recipientList-entry.js-object').click

        find('[name="title"]').fill_in with: 'attachment warning test'
        find('[data-name="body"]').send_keys 'please check the attachment'
      end

      # The mentioned attachment is missing: submitting asks for confirmation.
      #   The native click is used here: the click helper would await the ajax queue,
      #   which is impossible while the confirm dialog is open.
      dismiss_confirm do
        execute_script("$('.content.active .newTicket .js-submit').trigger('click')")
      end

      within(:active_content) do
        page.find('input#fileUpload_1[data-initialized="true"]', visible: :all).set([upload1, upload2])

        within '.newTicket .attachments' do
          expect(page).to have_text('upload1.txt')
          expect(page).to have_text('upload2.jpg')
        end

        # With the files attached, no confirmation is needed anymore.
        click '.js-submit'
      end

      expect(page).to have_css('.content.active .ticketZoom')

      within '.content.active .ticket-article-item:nth-child(1) .attachments' do
        expect(page).to have_text('upload1.txt')
        expect(page).to have_text('upload2.jpg')
      end
    end

    # Ported from test/browser/agent_ticket_create_attachment_missing_after_reload_test.rb
    #   (#1123): an attachment of an unsent new ticket survives a reload.
    it 'keeps the attachment of an unsent new ticket across a reload' do
      visit 'ticket/create'

      within(:active_content) do
        find('[name=customer_id_completion]').fill_in with: customer.email

        expect(page).to have_css('.recipientList-entry.js-object')
        first('.recipientList-entry.js-object').click

        find('[name="title"]').fill_in with: 'attachment reload test'
        find('[data-name="body"]').send_keys 'attachment reload test body'

        page.find('input#fileUpload_1[data-initialized="true"]', visible: :all).set(upload1)

        within '.newTicket .attachments' do
          expect(page).to have_text('upload1.txt')
        end
      end

      wait.until { Taskbar.last&.state.to_s.include?('attachment reload test') }

      page.refresh

      within '.content.active .newTicket .attachments' do
        expect(page).to have_text('upload1.txt')
      end
    end
  end

  describe 'in the ticket zoom' do
    let(:ticket)  { create(:ticket, group:, customer:) }
    let(:article) { create(:ticket_article, ticket:) }

    def authenticate
      create(:store,
             object:      'Ticket::Article',
             o_id:        article.id,
             data:        'old attachment content',
             filename:    'upload2.jpg',
             preferences: { 'Content-Type' => 'image/jpeg' })

      agent
    end

    def zoom_file_input
      page.first('.content.active .article-add input[type="file"]', visible: :all)
    end

    it 'warns about the keyword, isolates attachments per article and requires a body' do
      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        find('.article-new [data-name="body"]').send_keys 'some text with the word attachment'
      end

      dismiss_confirm do
        execute_script("$('.content.active .js-submit:visible').first().trigger('click')")
      end

      within(:active_content) do
        zoom_file_input.set(upload1)

        within '.article-add .attachments' do
          expect(page).to have_text('upload1.txt')
        end

        click '.js-submit'
      end

      expect(page).to have_no_css('.content.active .js-reset')

      # The new article carries only its own attachment, not the one of the first article.
      within '.content.active .ticket-article-item:last-child .attachments' do
        expect(page).to have_text('upload1.txt')
        expect(page).to have_no_text('upload2.jpg')
      end

      # An attachment without any body opens the missing-body warning dialog.
      within(:active_content) do
        zoom_file_input.set(upload1)

        click '.js-submit'
      end

      in_modal do
        expect(page).to have_text('missing')

        click_on 'Cancel'
      end

      # With a body present, the update goes through and shows the attachment.
      within(:active_content) do
        find('.article-new [data-name="body"]').send_keys 'now submit should work'

        click '.js-submit'
      end

      expect(page).to have_no_css('.content.active .js-reset')

      within '.content.active .ticket-article-item:last-child .attachments' do
        expect(page).to have_text('upload1.txt')
      end
    end

    # Ported from test/browser/agent_ticket_update_with_attachment_refresh_test.rb
    #   (#1123): an attachment of an unsent zoom update survives a reload.
    it 'keeps the attachment of an unsent update across a reload' do
      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        find('.article-new [data-name="body"]').send_keys 'keep me'

        zoom_file_input.set(upload1)

        within '.article-add .attachments' do
          expect(page).to have_text('upload1.txt')
        end
      end

      wait.until { Taskbar.last&.state.to_s.include?('keep me') }

      page.refresh

      within '.content.active .article-add .attachments' do
        expect(page).to have_text('upload1.txt')
      end
    end

    it 'disables the submit button while a large upload is running' do
      large_file = Rails.root.join('tmp/zammad_large_upload_spec.bin')
      File.binwrite(large_file, SecureRandom.random_bytes(24.megabytes))

      visit "#ticket/zoom/#{ticket.id}"

      within(:active_content) do
        find('.article-new [data-name="body"]').send_keys 'added attachment'

        zoom_file_input.set(large_file)
      end

      expect(page).to have_css('.content.active .js-submit:disabled', wait: 10)
      expect(page).to have_no_css('.content.active .js-submit:disabled', wait: 240)

      within(:active_content) do
        click '.js-submit'
      end

      expect(page).to have_no_css('.content.active .js-reset')
    ensure
      FileUtils.rm_f(large_file)
    end
  end
end
