# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile_old/examples/reply_article_examples'

RSpec.describe 'Mobile > Ticket > Article actions', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)              { Group.find_by(name: 'Users') }
  let(:agent)              { create(:agent, groups: [group]) }
  let(:customer)           { create(:customer, email: 'customer@example.com') }
  let(:ticket)             { create(:ticket, customer: customer, group: group) }
  let(:to)                 { nil }
  let(:new_to)             { nil }
  let(:result_to)          { new_to || to }
  let(:cc)                 { nil }
  let(:article_subject)    { nil }
  let(:before_click)       { -> {} }
  let(:after_click)        { -> {} }
  let(:new_subject)        { nil }
  let(:trigger_label)      { 'Reply' }
  let(:text_exact)         { true }
  let(:current_text)       { '' }
  let(:new_text)           { 'This is a note' }
  let(:result_attachments) { [Store.last] }
  let(:result_text)        { new_text || current_text }
  let(:in_reply_to)        { article.message_id }
  let(:type_id)            { article.type_id }

  def select_text(selector)
    js = %{
      var range = document.createRange();
      var selection = window.getSelection();
      range.selectNodeContents(document.querySelector('#{selector}'));
      selection.removeAllRanges();
      selection.addRange(range);
    }
    page.execute_script(js)
  end

  def open_article_reply_dialog()
    article

    visit "/tickets/#{ticket.id}"

    wait_for_form_to_settle('form-ticket-edit')
    wait_for_gql('shared/entities/ticket/graphql/queries/ticket/articles.graphql')

    before_click.call

    find_button('Article actions').click
    find_button(trigger_label).click
  end

  # FIXME: This test is too unstable in Chrome, probably due to a race condition in the signature
  #   handling of the editor. We need to find a way to reliably test this, but for now we will skip it.
  before do
    skip 'Skipping due to signature handling issues in Chrome' if Capybara.current_driver == :zammad_chrome
  end

  # we test article creation mostly on the backend because Node.js doesn't support prose-mirror
  context 'when article was created as email' do
    let(:signature) { create(:signature, active: true, body: "\#{user.firstname}<br>Signature!") }
    let(:group)          { create(:group, signature: signature) }
    let(:to)             { [Mail::AddressList.new(article.to).addresses.first.address] }
    let(:article)        { create(:ticket_article, :outbound_email, ticket: ticket) }
    let(:current_text)   { "#{agent.firstname}\nSignature!" }
    let(:signature_html) { "<div data-signature=\"true\" dir=\"auto\" data-signature-id=\"#{signature.id}\"><p dir=\"auto\">#{agent.firstname}<br dir=\"auto\">Signature!</p></div><p dir=\"auto\"></p>" }
    let(:result_text)    { start_with("<p dir=\"auto\">This is a note</p>#{signature_html}") }

    let(:after_click) do
      lambda {
        # wait for signature to be added
        wait_for_test_flag('editor.signatureAdd')
      }
    end

    context 'with default fields as outbound email' do
      include_examples 'mobile app: reply article', 'Email', attachments: true do
        let(:article) { create(:ticket_article, :outbound_email, ticket: ticket, from: 'from-email@example.com', to: 'to-email@example.com') }
        let(:to) { ['to-email@example.com'] }
      end
    end

    context 'with default fields as inbound email' do
      include_examples 'mobile app: reply article', 'Email', attachments: true do
        let(:article) { create(:ticket_article, :inbound_email, ticket: ticket, from: 'from-email@example.com', to: 'to-email@example.com') }
        let(:to) { ['from-email@example.com'] }
      end
    end

    context 'with default fields when article has type phone' do
      let(:type_id) { Ticket::Article::Type.find_by(name: 'email').id }

      context 'when agent sent article take article email' do
        include_examples 'mobile app: reply article', 'Email', attachments: true do
          let(:article) { create(:ticket_article, :outbound_phone, ticket: ticket, to: 'to-email@example.com') }
          let(:to)      { ['to-email@example.com'] }
        end
      end

      context 'when customer sent article from phone take customer email' do
        include_examples 'mobile app: reply article', 'Email', attachments: true do
          let(:article) { create(:ticket_article, :inbound_phone, ticket: ticket, from: '+423424235533') }
          let(:to) { ['customer@example.com'] }
        end
      end
    end

    context 'with selected text and quote header' do
      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', true)
      end

      include_examples 'mobile app: reply article', 'Email', attachments: true do
        let(:before_click) do
          lambda {
            select_text('.Content')
          }
        end
        let(:current_text) { %r{On .+, #{article.created_by.fullname} wrote:\s+#{article.body}\s+#{agent.firstname}\nSignature!} }
        let(:result_text)  do
          msg = '<p dir="auto">This is a note<br dir="auto"></p>'
          msg += '<blockquote dir="auto" type="cite">'
          msg += "<p dir=\"auto\">On .+, #{article.created_by.fullname} wrote:</p><p dir=\"auto\"></p>"
          msg += "<p dir=\"auto\">#{article.body}</p>"
          msg += '</blockquote><p dir="auto"></p>'
          msg += signature_html
          a_string_matching(Regexp.new(msg))
        end
      end
    end

    context 'with selected text without quote header' do
      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
      end

      include_examples 'mobile app: reply article', 'Email', attachments: true do
        let(:before_click) do
          lambda {
            select_text('.Content')
          }
        end
        let(:current_text) { "#{article.body}\n\n#{agent.firstname}\nSignature!" }
        let(:result_text)  do
          start_with("<p dir=\"auto\">This is a note<br dir=\"auto\"></p><blockquote dir=\"auto\" type=\"cite\"><p dir=\"auto\">#{article.body}</p></blockquote><p dir=\"auto\"></p>#{signature_html}")
        end
      end
    end

    context 'with selected text when new article is already written' do
      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
      end

      include_examples 'mobile app: reply article', 'Email', attachments: true, form_updater_gql_number: 4 do
        let(:before_click) do
          lambda {
            find_button('Add reply').click
            wait_for_form_updater(2)
            within_form(form_updater_gql_number: 2) do
              find_editor('Text').type('Text before replying')
            end
            find_button('Done').click
            wait_for_test_flag('ticket-article-reply.closed')
            select_text('.Content')
          }
        end

        let(:after_click) do
          lambda {
            # wait for signature to be added
            wait_for_test_flag('editor.signatureAdd')
          }
        end

        let(:current_text) { "#{article.body}\n\nText before replying\n\n#{agent.firstname}\nSignature!" }
        let(:result_text)  do
          start_with("<p dir=\"auto\">This is a note<br dir=\"auto\"></p><blockquote dir=\"auto\" type=\"cite\"><p dir=\"auto\">#{article.body}</p></blockquote><p dir=\"auto\"></p><p dir=\"auto\">Text before replying</p><p dir=\"auto\"></p>#{signature_html}")
        end
      end
    end

    context 'when full quote is enabled and new article is already written' do
      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
        Setting.set('ui_ticket_zoom_article_email_full_quote', true)
      end

      include_examples 'mobile app: reply article', 'Email', attachments: true, form_updater_gql_number: 4 do
        let(:before_click) do
          lambda {
            find_button('Add reply').click
            wait_for_form_updater(2)
            within_form(form_updater_gql_number: 2) do
              find_editor('Text').type('Text before replying')
            end
            find_button('Done').click
            wait_for_test_flag('ticket-article-reply.closed')
          }
        end

        let(:after_click) do
          lambda {
            # wait for signature to be added
            wait_for_test_flag('editor.signatureAdd')
          }
        end

        let(:signature_html) { "<div data-signature=\"true\" dir=\"auto\" data-signature-id=\"#{signature.id}\"><p dir=\"auto\">#{agent.firstname}<br dir=\"auto\">Signature!</p></div>" }
        let(:current_text)   { "#{agent.firstname}\nSignature!\n\n#{article.body}\n\nText before replying" }
        let(:result_text) do
          start_with("<p dir=\"auto\">This is a note</p>#{signature_html}<p dir=\"auto\"></p><blockquote dir=\"auto\" type=\"cite\"><p dir=\"auto\">#{article.body}</p></blockquote><p dir=\"auto\"></p><p dir=\"auto\">Text before replying</p>")
        end
      end
    end

    context 'when article has multiple email addresses, can reply all' do
      include_examples 'mobile app: reply article', 'Email', attachments: true do
        let(:trigger_label) { 'Reply all' }
        let(:to)            { ['e1@example.com', 'e2@example.com'] }
        let(:cc)            { ['e3@example.com'] }
        let(:article)       { create(:ticket_article, :outbound_email, ticket: ticket, to: to.join(', '), cc: cc.join(', ')) }
      end
    end

    context 'when subject is enabled' do
      before do
        Setting.set('ui_ticket_zoom_article_email_subject', true)
      end

      context 'when article has a subject use subject' do
        include_examples 'mobile app: reply article', 'Email', attachments: true do
          let(:article_subject) { 'Hello World' }
          let(:article) { create(:ticket_article, :outbound_email, ticket: ticket, subject: article_subject) }
        end
      end

      context 'when article doesn\'t have a subject use ticket title' do
        include_examples 'mobile app: reply article', 'Email', attachments: true do
          let(:article) { create(:ticket_article, :outbound_email, ticket: ticket, subject: nil) }
          let(:article_subject) { ticket.title }
        end
      end
    end

    context 'when adding multiple replies' do
      before do
        article
      end

      it 'keeps signature' do
        visit "/tickets/#{ticket.id}"

        wait_for_form_to_settle('form-ticket-edit')
        wait_for_gql('shared/entities/ticket/graphql/queries/ticket/articles.graphql')

        find_button('Article actions').click
        find_button('Reply').click

        wait_for_test_flag('editor.signatureAdd')

        expect(find_editor('Text')).to have_text_value("#{agent.firstname}\nSignature!")

        find_editor('Text').clear

        expect(find_editor('Text')).to have_text_value('', exact: true)

        find_button('Done').click

        wait_for_test_flag('ticket-article-reply.closed')

        find_button('Article actions').click
        find_button('Reply').click

        wait_for_form_updater(3)

        expect(find_editor('Text')).to have_text_value("#{agent.firstname}\nSignature!")
      end
    end

    context 'when forwarding email' do
      let(:trigger_label) { 'Forward' }
      let(:to)              { [] }
      let(:new_to)          { 'test@example.com' }
      let(:article)         { create(:ticket_article, :outbound_email, ticket: ticket, subject: 'Article Subject') }
      let(:article_subject) { article.subject }
      let(:text_to)         { article.to }
      let(:current_text) do
        msg = "#{agent.firstname}\nSignature!"
        msg += '\n\n---Begin forwarded message:---\n\n'
        msg += "Subject: #{article_subject}\n"
        msg += 'Date: \\d{2}/\\d{2}/\\d{4} \\d{1,2}:\\d{1,2} (am|pm)\n'
        msg += "To: #{text_to}\n\n"
        msg += article.body
        Regexp.new(msg)
      end
      let(:in_reply_to) { '' }
      let(:result_text) do
        msg = '<p dir="auto">This is a note</p>' # new message
        msg += "<div data-signature=\"true\" dir=\"auto\" data-signature-id=\"#{signature.id}\"><p dir=\"auto\">#{agent.firstname}<br dir=\"auto\">Signature!</p></div><p dir=\"auto\"></p>" # signature is before forwarded message
        msg += '<p dir="auto">---Begin forwarded message:---</p><p dir="auto"></p>' # new lines and "before" message
        # blockquote with original message and header with subject, date and "to"
        msg += '<blockquote dir="auto" type="cite">'
        msg += "<p dir=\"auto\">Subject: #{article_subject}<br dir=\"auto\">"
        msg += 'Date: \\d{2}/\\d{2}/\\d{4} \\d{1,2}:\\d{1,2} (am|pm)<br dir=\"auto\">'
        msg += "To: #{escape_html_wo_single_quotes(text_to)}<br dir=\"auto\"></p>"
        msg += "<p dir=\"auto\">#{article.body}</p>"
        msg += '</blockquote>'
        msg += '<p dir="auto"></p>'
        a_string_matching(Regexp.new(msg))
      end

      before do
        Setting.set('ui_ticket_zoom_article_email_subject', true)
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', true)
      end

      context 'with attachments' do
        let(:result_attachments) { Store.last(2) }
        let(:article) do
          article = create(:ticket_article, :outbound_email, ticket: ticket, subject: 'Article Subject')
          create(
            :store,
            object:   'Ticket::Article',
            o_id:     article.id,
            data:     Rails.root.join('spec/fixtures/files/image/small.png').binread,
            filename: 'small-original.png'
          )
          article
        end

        include_examples 'mobile app: reply article', 'Email', attachments: true
      end

      context 'without attachments' do
        include_examples 'mobile app: reply article', 'Email', attachments: true
      end

      context 'when forwarding phone article' do
        let(:article) { create(:ticket_article, :outbound_phone, ticket: ticket) }
        let(:text_to) { "#{ticket.customer.fullname} <#{ticket.customer.email}>" }
        let(:type_id) { Ticket::Article::Type.find_by(name: 'email').id }

        include_examples 'mobile app: reply article', 'Email', attachments: true
      end

      context 'without a header' do
        let(:current_text) do
          msg = "#{agent.firstname}\nSignature!"
          msg += "\n\n---Begin forwarded message:---\n\n"
          msg += article.body
          Regexp.new(msg)
        end
        let(:result_text) do
          msg = '<p dir="auto">This is a note</p>' # new message
          msg += "<div data-signature=\"true\" dir=\"auto\" data-signature-id=\"#{signature.id}\"><p dir=\"auto\">#{agent.firstname}<br dir=\"auto\">Signature!</p></div><p dir=\"auto\"></p>" # signature is before forwarded message
          msg += '<p dir="auto">---Begin forwarded message:---</p><p dir="auto"></p>' # new lines and "before" message
          # blockquote with original message and no header
          msg += "<blockquote dir=\"auto\" type=\"cite\"><p dir=\"auto\">#{article.body}</p></blockquote><p dir=\"auto\"></p>"
          a_string_matching(Regexp.new(msg))
        end

        before do
          Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
        end

        include_examples 'mobile app: reply article', 'Email', attachments: true
      end
    end
  end

  context 'when article was created as sms' do
    let(:article) do
      create(
        :ticket_article,
        ticket: ticket,
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        type:   Ticket::Article::Type.lookup(name: 'sms'),
        from:   '+41234567890'
      )
    end

    context 'with default fields' do
      include_examples 'mobile app: reply article', 'SMS', 'with default fields' do
        let(:to) { ['+41234567890'] }
      end
    end

    context 'with additional custom recipient' do
      let(:phone_number) { Faker::PhoneNumber.cell_phone_in_e164 }

      include_examples 'mobile app: reply article', 'SMS', 'to another recipient number' do
        let(:new_to)    { phone_number }
        let(:result_to) { [phone_number, '+41234567890'] }
      end
    end

    it 'cannot create large article' do
      open_article_reply_dialog

      find_editor('Text').type(Faker::Lorem.characters(number: 161))

      click_on('Save')

      expect(find_editor('Text')).to have_text('This field must contain between 1 and 160 characters')
    end

    # TODO: Check how we can test sending to customer numbers.
  end

  context 'when article was created as a telegram message' do
    let(:article) do
      create(
        :ticket_article,
        ticket: ticket,
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        type:   Ticket::Article::Type.lookup(name: 'telegram personal-message'),
      )
    end

    include_examples 'mobile app: reply article', 'Telegram', attachments: true
  end

  context 'when article was created as a facebook post' do
    let(:article) do
      create(
        :ticket_article,
        ticket: ticket,
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        type:   Ticket::Article::Type.lookup(name: 'facebook feed post'),
      )
    end

    include_examples 'mobile app: reply article', 'Facebook', attachments: false, no_form_updater: true do
      let(:type_id)     { Ticket::Article::Type.lookup(name: 'facebook feed comment').id }
      let(:in_reply_to) { nil }
    end
  end
end
