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
    find_button('Add reply').click
  end

  context 'when creating a new article as an agent', authenticated_as: :agent do
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

    it 'creates a public email (default)' do
      visit "/tickets/#{ticket.id}"
      find_button('Add reply').click

      find_select('Article Type', visible: :all).select_option('Email')

      find_autocomplete('To').search_for_option('zammad_test_to@zammad.com', gql_number: 1)
      find_autocomplete('CC').search_for_option('zammad_test_cc@zammad.com', gql_number: 2)

      find_editor('Text').type('This is a note!')

      find_button('Done').click
      find_button('Save ticket').click

      wait_for_ticket_edit

      expect(Ticket::Article.last).to have_attributes(
        type_id:      Ticket::Article::Type.lookup(name: 'email').id,
        to:           'zammad_test_to@zammad.com',
        cc:           'zammad_test_cc@zammad.com',
        internal:     false,
        content_type: 'text/html',
        body:         '<p>This is a note!</p>',
      )
    end

    it 'creates an internal email' do
      visit "/tickets/#{ticket.id}"
      find_button('Add reply').click

      find_select('Article Type', visible: :all).select_option('Email')

      visibility = find_select('Visibility', visible: :all)
      expect(visibility).to have_selected_option('Public')

      visibility.select_option('Internal')

      find_editor('Text').type('This is a note!')

      find_button('Done').click
      find_button('Save ticket').click

      wait_for_ticket_edit

      expect(Ticket::Article.last).to have_attributes(
        type_id:      Ticket::Article::Type.lookup(name: 'email').id,
        internal:     true,
        content_type: 'text/html',
        body:         '<p>This is a note!</p>',
      )
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

    # TODO: test security settings
  end
end
