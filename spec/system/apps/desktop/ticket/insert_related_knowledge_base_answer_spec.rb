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
end
