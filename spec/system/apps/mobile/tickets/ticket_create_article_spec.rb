# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile/examples/create_article_examples'

RSpec.describe 'Mobile > Ticket > Create article', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)     { Group.find_by(name: 'Users') }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:customer)  { create(:customer) }
  let(:ticket)    { create(:ticket, customer: customer, group: group) }

  def wait_for_ticket_edit
    wait_for_gql('apps/mobile/pages/ticket/graphql/mutations/update.graphql')
  end

  def save_article
    find_button('Done').click
    find_button('Save ticket').click

    wait_for_ticket_edit
  end

  def open_article_dialog
    visit "/tickets/#{ticket.id}"

    wait_for_form_to_settle('form-ticket-edit')

    find_button('Add reply').click
  end

  context 'when creating a new article as an agent', authenticated_as: :agent do
    it 'disables the done button when the form is not dirty' do
      open_article_dialog

      expect(find_button('Done', disabled: true).disabled?).to be(true)
    end

    it 'enables the done button when the form is dirty' do
      open_article_dialog
      find_editor('Text').type('foobar')

      expect(find_button('Done').disabled?).to be(false)
    end

    it 'creates an internal note (default)' do
      open_article_dialog

      expect(find_select('Article Type', visible: :all)).to have_selected_option('Note')
      expect(find_select('Visibility', visible: :all)).to have_selected_option('Internal')

      text = find_editor('Text')
      expect(text).to have_text_value('', exact: true)
      text.type('This is a note')

      save_article

      expect(Ticket::Article.last).to have_attributes(
        type_id:      Ticket::Article::Type.lookup(name: 'note').id,
        internal:     true,
        content_type: 'text/html',
        sender:       Ticket::Article::Sender.lookup(name: 'Agent'),
        body:         '<p>This is a note</p>',
      )
    end

    it 'creates a public note' do
      open_article_dialog

      find_select('Visibility', visible: :all).select_option('Public')

      text = find_editor('Text')
      expect(text).to have_text_value('', exact: true)
      text.type('This is a note!')

      save_article

      expect(Ticket::Article.last).to have_attributes(
        type_id:      Ticket::Article::Type.lookup(name: 'note').id,
        internal:     false,
        content_type: 'text/html',
        body:         '<p>This is a note!</p>',
      )
    end

    context 'when creating an email' do
      let(:signature) { create(:signature, active: true, body: "\#{user.firstname}<br>Signature!") }
      let(:group)     { create(:group, signature: signature) }

      it 'creates a public email (default)' do
        visit "/tickets/#{ticket.id}"
        find_button('Add reply').click

        find_select('Article Type', visible: :all).select_option('Email')

        wait_for_test_flag('editor.signatureAdd')

        find_editor('Text').type('This is a note!', click: false)

        find_autocomplete('To').search_for_option('zammad_test_to@zammad.com', gql_number: 1)
        find_autocomplete('CC').search_for_option('zammad_test_cc@zammad.com', gql_number: 2)

        find_button('Done').click
        find_button('Save ticket').click

        wait_for_ticket_edit

        expect(Ticket::Article.last).to have_attributes(
          type_id:      Ticket::Article::Type.lookup(name: 'email').id,
          to:           'zammad_test_to@zammad.com',
          cc:           'zammad_test_cc@zammad.com',
          internal:     false,
          content_type: 'text/html',
          body:         "<p>This is a note!</p><p></p><div data-signature=\"true\" data-signature-id=\"#{signature.id}\"><p>#{agent.firstname}<br>Signature!</p></div>",
        )
      end

      it 'creates an internal email' do
        visit "/tickets/#{ticket.id}"
        find_button('Add reply').click

        find_select('Article Type', visible: :all).select_option('Email')

        wait_for_test_flag('editor.signatureAdd')

        find_editor('Text').type('This is a note!', click: false)

        visibility = find_select('Visibility', visible: :all)
        expect(visibility).to have_selected_option('Public')

        visibility.select_option('Internal')

        find_button('Done').click
        find_button('Save ticket').click

        wait_for_ticket_edit

        expect(Ticket::Article.last).to have_attributes(
          type_id:      Ticket::Article::Type.lookup(name: 'email').id,
          internal:     true,
          content_type: 'text/html',
          body:         "<p>This is a note!</p><p></p><div data-signature=\"true\" data-signature-id=\"#{signature.id}\"><p>#{agent.firstname}<br>Signature!</p></div>",
        )
      end
    end

    it 'changes ticket data together with the article' do
      open_article_dialog

      find_editor('Text').type('This is a note!')

      # close reply dialog
      find_button('Done').click

      # go to the ticket edit view
      find_link(ticket.title).click

      find_input('Ticket title').type('New title')
      find_button('Save ticket').click

      wait_for_ticket_edit

      expect(ticket.reload.title).to eq('New title')
      expect(Ticket::Article.last).to have_attributes(
        type_id:      Ticket::Article::Type.lookup(name: 'note').id,
        content_type: 'text/html',
        body:         '<p>This is a note!</p>',
      )
    end

    context 'when creating a phone article' do
      include_examples 'create article', 'Phone', attachments: true, conditional: false do
        let(:article) { create(:ticket_article, :outbound_phone, ticket: ticket) }
        let(:type)         { Ticket::Article::Type.lookup(name: 'phone') }
        let(:content_type) { 'text/html' }
      end
    end

    context 'when creating sms article' do
      include_examples 'create article', 'Sms', conditional: true do
        let(:article) do
          create(
            :ticket_article,
            ticket: ticket,
            type:   Ticket::Article::Type.find_by(name: 'sms'),
          )
        end
        let(:type)         { Ticket::Article::Type.lookup(name: 'sms') }
        let(:content_type) { 'text/plain' }
      end
    end

    context 'when creating telegram article' do
      include_examples 'create article', 'Telegram', attachments: true do
        let(:article) do
          create(
            :ticket_article,
            ticket: ticket,
            type:   Ticket::Article::Type.find_by(name: 'telegram personal-message'),
          )
        end
        let(:type)         { Ticket::Article::Type.lookup(name: 'telegram personal-message') }
        let(:content_type) { 'text/plain' }
      end
    end

    context 'when replying to twitter status ticket' do
      include_examples 'create article', 'Twitter', attachments: false do
        let(:article) do
          create(
            :twitter_article,
            ticket: ticket,
            sender: Ticket::Article::Sender.lookup(name: 'Customer'),
          )
        end
        let(:type)         { Ticket::Article::Type.lookup(name: 'twitter status') }
        let(:content_type) { 'text/plain' }
        let(:result_text)  { "#{new_text}\n/#{agent.firstname.first}#{agent.lastname.first}" }
      end
    end

    context 'when replying to twitter dm ticket' do
      include_examples 'create article', 'Twitter', attachments: false do
        let(:article) do
          create(
            :twitter_dm_article,
            ticket: ticket,
            sender: Ticket::Article::Sender.lookup(name: 'Customer'),
          )
        end
        let(:type)         { Ticket::Article::Type.lookup(name: 'twitter direct-message') }
        let(:content_type) { 'text/plain' }
        let(:to)           { article.from }
        let(:result_text)  { "#{new_text}\n/#{agent.firstname.first}#{agent.lastname.first}" }
      end
    end

    context 'when replying to a facebook post' do
      include_examples 'create article', 'Facebook', attachments: false do
        let(:article) do
          create(
            :ticket_article,
            ticket: ticket,
            sender: Ticket::Article::Sender.lookup(name: 'Customer'),
            type:   Ticket::Article::Type.lookup(name: 'facebook feed post'),
          )
        end
        let(:type)         { Ticket::Article::Type.lookup(name: 'facebook feed comment') }
        let(:content_type) { 'text/plain' }
      end
    end
    # TODO: test security settings
  end
end
