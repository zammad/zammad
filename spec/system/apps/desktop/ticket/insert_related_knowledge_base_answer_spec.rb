# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Desktop > Ticket > Insert related knowledge base answer', app: :desktop_view, authenticated_as: :authenticate, type: :playwright do
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

  def add_internal_note
    add_internal_note_button.click
    wait_for_editor_ready(editor('Text'))
  end

  before do
    open_desktop_ticket(ticket)
  end

  it 'offers the linked and the suggested answer before a search term is typed, and inserts one with its attachment' do
    add_internal_note
    type_in_editor('Text', '??')

    answers = page.get_by_role('listbox', name: 'Knowledge base articles')
    expect(answers).to contain_text('Start typing to search in knowledge base…')

    linked    = answers.get_by_role('group', name: 'Linked knowledge', exact: true).get_by_role('option')
    suggested = answers.get_by_role('group', name: 'Suggested knowledge', exact: true).get_by_role('option')

    expect(linked).to have_count(1)
    expect(linked).to contain_text(linked_translation.title)
    expect(suggested).to have_count(1)
    expect(suggested).to contain_text(suggested_translation.title)

    linked.click

    expect(editor('Text')).to contain_text(linked_translation.content.body)
    # The file list renders the extension apart from the base name.
    expect(main_content).to contain_text(%r{hello_world\s*\.txt})
  end

  context 'when inserting from the sidebar' do
    def related_answer_row(translation)
      content_sidebar.get_by_role('listitem').filter(has: page.get_by_role('link', name: translation.title))
    end

    # The pointer on the row opens the answer's popover over its actions, the keyboard does not.
    def insert_from_sidebar(translation)
      button = related_answer_row(translation).get_by_role('button', name: 'Insert knowledge base answer')
      button.focus
      button.press('Enter')
    end

    # The row actions only show while the row is hovered or focused, which is not what is checked here.
    it 'offers the insert action only while an article is being written' do
      row = related_answer_row(linked_translation)

      expect(row.get_by_role('button', name: 'Unlink knowledge base answer')).to have_count(1)
      expect(row.get_by_role('button', name: 'Insert knowledge base answer')).to have_count(0)

      add_internal_note

      expect(row.get_by_role('button', name: 'Insert knowledge base answer')).to have_count(1)
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
        main_content.get_by_role('button', name: 'Reply', exact: true).click

        expect(editor('Text').get_by_role('blockquote')).to contain_text('Customer question.')

        insert_from_sidebar(linked_translation)

        expect(editor('Text')).to contain_text(linked_translation.content.body)

        text = editor('Text').inner_text
        expect(text.index(linked_translation.content.body)).to be < text.index('Customer question.')
      end
    end
  end
end
