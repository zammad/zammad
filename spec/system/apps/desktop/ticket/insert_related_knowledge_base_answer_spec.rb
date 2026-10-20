# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Insert related knowledge base answer', app: :desktop_view, authenticated_as: :authenticate, type: :system do
  include_context 'basic Knowledge Base'

  let(:ticket)                { create(:ticket, group: Group.find_by(name: 'Users')) }
  let(:linked_translation)    { published_answer.translations.first }
  let(:suggested_translation) { internal_answer.translations.first }

  def authenticate
    setup_ai_provider('zammad_ai')
    Setting.set('vectordb_enabled', true)

    allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
    # The knowledge base answer factory triggers the vector index callback, which must not reach
    #   Elasticsearch in this spec.
    allow(Service::AI::VectorDB::Available).to receive(:execute).with(ping: false).and_return(false)
    allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
      .to receive(:execute).and_return({ answers: [{ translation: suggested_translation, score: 0.9 }], pending: false })

    create(:link, from: ticket, to: linked_translation)

    true
  end

  before do
    wait_for_setting('kb_active', true)
    wait_for_setting('vectordb_enabled', true)

    visit "/tickets/#{ticket.id}"
    wait_for_form_to_settle("form-ticket-edit-#{ticket.id}")
  end

  it 'offers the linked and the suggested answer before a search term is typed, and inserts one with its attachment' do
    within 'main' do
      find('button', text: 'Add internal note').click

      editor = find_editor('Text')
      wait_for_editor_ready(editor)
      editor.input_element.send_keys('??')
    end

    within '[data-test-id="mention-knowledge-base"]' do
      expect(page).to have_text('Start typing to search in knowledge base…')
        .and have_text('Linked')
        .and have_text('Suggested knowledge')

      within '[role="group"][aria-labelledby$="-section-linked"]' do
        expect(page).to have_css('[role="option"]', count: 1, text: linked_translation.title)
      end

      within '[role="group"][aria-labelledby$="-section-suggested"]' do
        expect(page).to have_css('[role="option"]', count: 1, text: suggested_translation.title)
      end

      find('[role="option"]', text: linked_translation.title).click
    end

    within '#ticketArticleReplyForm' do
      expect(find_editor('Text').input_element).to have_text(linked_translation.content.body)
      # The file list renders the extension apart from the base name.
      expect(page).to have_text(%r{hello_world\s*\.txt})
    end
  end

  context 'when inserting from the sidebar' do
    def related_answer_row(translation)
      find('#ticket-ai-knowledge-base-answers li', text: translation.title)
    end

    def insert_from_sidebar(translation)
      button = related_answer_row(translation).find_button('Insert knowledge base answer', visible: :all)

      # The row reveals its actions on focus as well as on hover, and focus does not depend on where
      #   the pointer rests.
      button.evaluate_script('this.focus()')
      button.click
    end

    def editor_text
      find_editor('Text').input_element.text
    end

    # The row actions only show while the row is hovered or focused, which is not what is checked here.
    it 'offers the insert action only while an article is being written' do
      within related_answer_row(linked_translation) do
        expect(page).to have_button('Unlink knowledge base answer', visible: :all)
        expect(page).to have_no_button('Insert knowledge base answer', visible: :all)
      end

      within('main') { find('button', text: 'Add internal note').click }
      wait_for_editor_ready(find_editor('Text'))

      within related_answer_row(linked_translation) do
        expect(page).to have_button('Insert knowledge base answer', visible: :all)
      end
    end

    context 'with a full quote reply' do
      let(:article) do
        create(:ticket_article, :inbound_email, ticket:, body: '<p>Customer question.</p>', content_type: 'text/html')
      end

      prepend_before do
        Setting.set('ui_ticket_zoom_article_email_full_quote', true)
        article
      end

      it 'inserts the answer above the quote when no cursor was placed' do
        within "#article-#{article.id}" do
          find('button', exact_text: 'Reply', visible: :all).click
        end

        within '#ticketArticleReplyForm' do
          expect(page).to have_css('blockquote', text: 'Customer question.')
        end

        insert_from_sidebar(linked_translation)

        expect(page).to have_css('#ticketArticleReplyForm [role="textbox"]', text: linked_translation.content.body)

        text = editor_text
        expect(text.index(linked_translation.content.body)).to be < text.index('Customer question.')
      end
    end
  end
end
