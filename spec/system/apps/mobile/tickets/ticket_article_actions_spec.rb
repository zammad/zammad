# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile/examples/reply_article_examples'

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

  # we test article creation mostly on the backend because Node.js doesn't support prose-mirror
  context 'when article was created as email' do
    let(:signature) { create(:signature, active: true, body: "\#{user.firstname}<br>Signature!") }
    let(:group)        { create(:group, signature: signature) }
    let(:to)           { [Mail::AddressList.new(article.to).addresses.first.address] }
    let(:article)      { create(:ticket_article, :outbound_email, ticket: ticket) }
    let(:current_text) { "#{agent.firstname}\nSignature!" }
    let(:result_text)  { "<p>This is a note</p><p></p><div data-signature=\"true\" data-signature-id=\"#{signature.id}\"><p>#{agent.firstname}<br>Signature!</p></div>" }
    let(:after_click)  do
      lambda {
        # wait for signature to be added
        wait_for_test_flag('editor.signatureAdd')
      }
    end

    context 'with default fields as outbound email' do
      include_examples 'reply article', 'Email', attachments: true do
        let(:article) { create(:ticket_article, :outbound_email, ticket: ticket, from: 'from-email@example.com', to: 'to-email@example.com') }
        let(:to) { ['to-email@example.com'] }
      end
    end

    context 'with default fields as inbound email' do
      include_examples 'reply article', 'Email', attachments: true do
        let(:article) { create(:ticket_article, :inbound_email, ticket: ticket, from: 'from-email@example.com', to: 'to-email@example.com') }
        let(:to) { ['from-email@example.com'] }
      end
    end

    context 'with default fields when article has type phone' do
      let(:type_id) { Ticket::Article::Type.find_by(name: 'email').id }

      context 'when agent sent article take article email' do
        include_examples 'reply article', 'Email', attachments: true do
          let(:article) { create(:ticket_article, :outbound_phone, ticket: ticket, to: 'to-email@example.com') }
          let(:to)      { ['to-email@example.com'] }
        end
      end

      context 'when customer sent article from phone take customer email' do
        include_examples 'reply article', 'Email', attachments: true do
          let(:article) { create(:ticket_article, :inbound_phone, ticket: ticket, from: '+423424235533') }
          let(:to) { ['customer@example.com'] }
        end
      end
    end

    context 'with selected text and quote header' do
      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', true)
      end

      include_examples 'reply article', 'Email', attachments: true do
        let(:before_click) do
          lambda {
            select_text('.Content')
          }
        end
        let(:current_text) { %r{On .+, #{article.created_by.fullname} wrote:\s+#{article.body}\s+#{agent.firstname}\nSignature!} }
        let(:result_text)  do
          a_string_matching(%r{<p>This is a note<br></p><blockquote type="cite"><p>On .+, #{article.created_by.fullname} wrote:<br><br>#{article.body}</p></blockquote><p></p><div data-signature="true" data-signature-id="#{signature.id}"><p>#{agent.firstname}<br>Signature!</p></div>})
        end
      end
    end

    context 'with selected text without quote header' do
      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
      end

      include_examples 'reply article', 'Email', attachments: true do
        let(:before_click) do
          lambda {
            select_text('.Content')
          }
        end
        let(:current_text) { "#{article.body}\n\n#{agent.firstname}\nSignature!" }
        let(:result_text)  do
          "<p>This is a note<br></p><blockquote type=\"cite\"><p>#{article.body}</p></blockquote><p></p><div data-signature=\"true\" data-signature-id=\"#{signature.id}\"><p>#{agent.firstname}<br>Signature!</p></div>"
        end
      end
    end

    context 'with selected text when new article is already written' do
      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
      end

      include_examples 'reply article', 'Email', attachments: true do
        let(:before_click) do
          lambda {
            find_button('Add reply').click
            find_editor('Text').type('Text before replying')
            find_button('Done').click
            wait_for_test_flag('ticket-article-reply.closed')
            select_text('.Content')
          }
        end
        let(:current_text) { "#{article.body}\n\nText before replying\n\n#{agent.firstname}\nSignature!" }
        let(:result_text)  do
          "<p>This is a note<br></p><blockquote type=\"cite\"><p>#{article.body}</p></blockquote><p></p><p>Text before replying</p><p></p><div data-signature=\"true\" data-signature-id=\"#{signature.id}\"><p>#{agent.firstname}<br>Signature!</p></div>"
        end
      end
    end

    context 'when full quote is enabled and new article is already written' do
      before do
        Setting.set('ui_ticket_zoom_article_email_full_quote_header', false)
        Setting.set('ui_ticket_zoom_article_email_full_quote', true)
      end

      include_examples 'reply article', 'Email', attachments: true do
        let(:before_click) do
          lambda {
            find_button('Add reply').click
            find_editor('Text').type('Text before replying')
            find_button('Done').click
            wait_for_test_flag('ticket-article-reply.closed')
          }
        end
        let(:current_text) { "#{agent.firstname}\nSignature!\n\n#{article.body}\n\nText before replying" }
        let(:result_text)  do
          "<p>This is a note<br></p><div data-signature=\"true\" data-signature-id=\"#{signature.id}\">\n<p>#{agent.firstname}<br>Signature!</p>\n<p></p>\n</div><blockquote type=\"cite\"><p>#{article.body}</p></blockquote><p></p><p>Text before replying</p>"
        end
      end
    end

    context 'when article has multiple email addresses, can reply all' do
      include_examples 'reply article', 'Email', attachments: true do
        let(:trigger_label) { 'Reply All' }
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
        include_examples 'reply article', 'Email', attachments: true do
          let(:article_subject) { 'Hello World' }
          let(:article) { create(:ticket_article, :outbound_email, ticket: ticket, subject: article_subject) }
        end
      end

      context 'when article doesn\'t have a subject use ticket title' do
        include_examples 'reply article', 'Email', attachments: true do
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

        find_button('Article actions').click
        find_button('Reply').click

        wait_for_test_flag('ticket-article-reply.opened')

        expect(find_editor('Text')).to have_text_value("#{agent.firstname}\nSignature!")
        find_editor('Text').clear
        expect(find_editor('Text')).to have_text_value('', exact: true)

        find_button('Done').click

        wait_for_test_flag('ticket-article-reply.closed')

        find_button('Article actions').click
        find_button('Reply').click

        wait_for_test_flag('ticket-article-reply.opened')

        expect(find_editor('Text')).to have_text_value("#{agent.firstname}\nSignature!")
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
      include_examples 'reply article', 'Sms', 'with default fields' do
        let(:to) { ['+41234567890'] }
      end
    end

    context 'with additional custom recipient' do
      let(:phone_number) { Faker::PhoneNumber.cell_phone_in_e164 }

      include_examples 'reply article', 'Sms', 'to another recipient number' do
        let(:new_to)    { phone_number }
        let(:result_to) { [phone_number, '+41234567890'] }
      end
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

    include_examples 'reply article', 'Telegram', attachments: true
  end

  context 'when article was created as a twitter status' do
    let(:article) do
      create(
        :twitter_article,
        ticket: ticket,
        sender: Ticket::Article::Sender.lookup(name: 'Customer'),
      )
    end

    include_examples 'reply article', 'Twitter', attachments: false do
      let(:current_text) { "#{article.from} " }
      let(:new_text)     { '' }
      let(:result_text)  { "#{article.from}&nbsp\n/#{agent.firstname.first}#{agent.lastname.first}" }
    end
  end

  context 'when article was created as a twitter dm' do
    include_examples 'reply article', 'Twitter', 'DM when sender is customer', attachments: false do
      let(:article) do
        create(
          :twitter_dm_article,
          ticket: ticket,
          sender: Ticket::Article::Sender.lookup(name: 'Customer'),
        )
      end
      let(:result_text) { "#{new_text}\n/#{agent.firstname.first}#{agent.lastname.first}" }
      let(:to) { [article.from] }
    end

    include_examples 'reply article', 'Twitter', 'DM when sender is agent', attachments: false do
      let(:article) do
        create(
          :twitter_dm_article,
          ticket: ticket,
          sender: Ticket::Article::Sender.lookup(name: 'Agent'),
        )
      end
      let(:result_text) { "#{new_text}\n/#{agent.firstname.first}#{agent.lastname.first}" }
      let(:to) { [article.to] }
    end
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

    include_examples 'reply article', 'Facebook', attachments: false do
      let(:type_id)     { Ticket::Article::Type.lookup(name: 'facebook feed comment').id }
      let(:in_reply_to) { nil }
    end
  end
end
