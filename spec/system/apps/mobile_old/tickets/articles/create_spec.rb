# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/apps/mobile_old/examples/create_article_examples'
require 'system/apps/mobile_old/examples/article_security_examples'

RSpec.describe 'Mobile > Ticket > Article > Create', app: :mobile, authenticated_as: :agent, type: :system do
  let(:group)     { Group.find_by(name: 'Users') }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:customer)  { create(:customer) }
  let(:ticket)    { create(:ticket, customer: customer, group: group, owner: agent) }

  def wait_for_ticket_edit(number: 1)
    wait_for_mutation('ticketUpdate', number: number)
  end

  def save_article(number: 1)
    find_button('Done').click
    wait_for_test_flag('ticket-article-reply.closed')

    find_button('Save').click

    wait_for_ticket_edit(number: number)
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

      expect(find_select('Channel', visible: :all)).to have_selected_option('Note')
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

    it 'doesn\'t show "save" button when part of ticket is changed and article is added' do
      visit "/tickets/#{ticket.id}/information"

      wait_for_form_to_settle('form-ticket-edit')

      find_input('Ticket title').type('foobar')
      click_on('Add reply')

      expect(find_select('Channel', visible: :all)).to have_selected_option('Note')
      expect(find_select('Visibility', visible: :all)).to have_selected_option('Internal')

      text = find_editor('Text')
      expect(text).to have_text_value('', exact: true)
      text.type('This is a note')

      save_article

      expect(page).to have_no_button('Save')
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

        find_select('Channel', visible: :all).select_option('Email')

        wait_for_test_flag('editor.signatureAdd')

        find_editor('Text').type('This is a note!')

        find_autocomplete('To').search_for_option('zammad_test_to@zammad.com', gql_number: 1)
        find_autocomplete('CC').search_for_option('zammad_test_cc@zammad.com', gql_number: 2)

        find_button('Save').click

        wait_for_ticket_edit

        expect(Ticket::Article.last).to have_attributes(
          type_id:      Ticket::Article::Type.lookup(name: 'email').id,
          to:           'zammad_test_to@zammad.com',
          cc:           'zammad_test_cc@zammad.com',
          internal:     false,
          content_type: 'text/html',
          body:         "<p>This is a note!</p><p><br></p><div data-signature=\"true\" data-signature-id=\"#{signature.id}\"><p>#{agent.firstname}<br>Signature!</p></div>",
        )
      end

      it 'creates an internal email' do
        visit "/tickets/#{ticket.id}"
        find_button('Add reply').click

        find_select('Channel', visible: :all).select_option('Email')

        wait_for_test_flag('editor.signatureAdd')

        find_editor('Text').type('This is a note!')

        find_autocomplete('To').search_for_option('zammad_test_to@zammad.com', gql_number: 1)

        visibility = find_select('Visibility', visible: :all)
        expect(visibility).to have_selected_option('Public')

        visibility.select_option('Internal')

        find_button('Save').click

        wait_for_ticket_edit

        expect(Ticket::Article.last).to have_attributes(
          type_id:      Ticket::Article::Type.lookup(name: 'email').id,
          internal:     true,
          content_type: 'text/html',
          body:         "<p>This is a note!</p><p><br></p><div data-signature=\"true\" data-signature-id=\"#{signature.id}\"><p>#{agent.firstname}<br>Signature!</p></div>",
        )
      end
    end

    context 'when an article was just deleted', current_user_id: -> { agent.id } do
      def delete_article(article_body, number: 1)
        wait_for_subscription_start('ticketArticleUpdates')

        within '[role="comment"]', text: article_body do
          find('[data-name="article-context"]').click
        end

        click_on 'Delete Article'
        click_on 'OK'

        wait_for_subscription_update('ticketArticleUpdates', number: number)
      end

      def create_article(article_body, number: 1)
        find_button('Add reply').click

        wait_for_test_flag('ticket-article-reply.opened')

        within_form(form_updater_gql_number: number) do
          text = find_editor('Text')
          expect(text).to have_text_value('', exact: true)
          text.type(article_body)
          expect(text).to have_text_value(article_body)
        end

        save_article(number: number)
      end

      context 'when deleting the first/last article' do
        it 'shows the correct articles' do
          visit "/tickets/#{ticket.id}"
          wait_for_form_to_settle('form-ticket-edit')

          create_article('Article 1')
          delete_article('Article 1')
          create_article('This is a new note', number: 2)

          expect(page).to have_no_text('Article 1')
            .and have_text('This is a new note')
        end
      end

      context 'when deleting an article in the middle' do
        it 'shows the correct articles' do
          visit "/tickets/#{ticket.id}"
          wait_for_form_to_settle('form-ticket-edit')

          create_article('Article 1')
          create_article('Article 2', number: 2)
          create_article('Article 3', number: 3)

          delete_article('Article 2')

          create_article('This is a new note', number: 4)

          expect(page).to have_text('Article 1')
            .and have_no_text('Article 2')
            .and have_text('This is a new note')
            .and have_text('Article 3')
        end
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
      find_button('Save').click

      wait_for_ticket_edit

      expect(ticket.reload.title).to eq('New title')
      expect(Ticket::Article.last).to have_attributes(
        type_id:      Ticket::Article::Type.lookup(name: 'note').id,
        content_type: 'text/html',
        body:         '<p>This is a note!</p>',
      )
    end

    context 'when creating a phone article' do
      include_examples 'mobile app: create article', 'Phone', attachments: true, conditional: false do
        let(:article)      { create(:ticket_article, :outbound_phone, ticket: ticket) }
        let(:type)         { Ticket::Article::Type.lookup(name: 'phone') }
        let(:content_type) { 'text/html' }
      end
    end

    context 'when creating sms article' do
      include_examples 'mobile app: create article', 'Sms', conditional: true do
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
      include_examples 'mobile app: create article', 'Telegram', attachments: true do
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
      include_examples 'mobile app: create article', 'Twitter', attachments: false do
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
      include_examples 'mobile app: create article', 'Twitter', attachments: false do
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
      include_examples 'mobile app: create article', 'Facebook', attachments: false do
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

    context 'when using suggestions' do
      let(:text_option) do
        content = "Hello, \#{ticket.customer.firstname}!"
        content += " Ticket \#{ticket.title} has group \#{ticket.group.name}."
        create(
          :text_module,
          name:    'test',
          content: content
        )
      end

      it 'text suggestion parses correctly' do
        create(:ticket_article, ticket: ticket)

        open_article_dialog

        find_editor('Text').type('::test')
        find('[role="option"]', text: text_option.name).click

        body = "Hello, #{ticket.customer.firstname}!"
        body += " Ticket #{ticket.title} has group #{ticket.group.name}."
        expect(find_editor('Text')).to have_text(body)
      end
    end

    # TODO: test security settings
  end

  context 'when creating a new article as a customer', authenticated_as: :customer do
    it 'creates an article with web type' do
      open_article_dialog

      text = find_editor('Text')
      expect(text).to have_text_value('', exact: true)
      text.type('This is a note')

      save_article

      expect(Ticket::Article.last).to have_attributes(
        type_id:      Ticket::Article::Type.lookup(name: 'web').id,
        internal:     false,
        content_type: 'text/html',
        sender:       Ticket::Article::Sender.lookup(name: 'Customer'),
        body:         '<p>This is a note</p>',
      )
    end

  end

  context 'when creating secured article', authenticated_as: :authenticate do
    def prepare_phone_article
      open_article_dialog
      find_select('Channel', visible: :all).select_option('Phone')
    end

    def prepare_email_article(with_body: false)
      open_article_dialog
      find_select('Channel', visible: :all).select_option('Email')
      find_autocomplete('To').search_for_option(customer.email, label: customer.fullname)

      find_editor('Text').type(Faker::Hacker.say_something_smart) if with_body
    end

    def submit_form
      save_article
    end

    it_behaves_like 'mobile app: article security', integration: :smime
    it_behaves_like 'mobile app: article security', integration: :pgp
  end

  context 'when inlining an image', authenticated_as: :agent do
    it 'correctly compresses image' do
      open_article_dialog

      find_editor('Text').type(Faker::Hacker.say_something_smart)
      click_on('Add image') # inserts an invisible input
      find('[data-test-id="editor-image-input"]', visible: :all).attach_file(Rails.root.join('spec/fixtures/files/image/large2.png'))
      wait_for_test_flag('editor.imageResized')

      save_article

      # The fize will always be less than it actually is even without resizing
      # Chrome has the best compression, so we check that actual value is lower than Firefox's compresssion
      expect(Store.last.size.to_i).to be <= 25_686
    end
  end
end
