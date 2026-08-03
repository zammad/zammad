# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Link knowledge base answer', type: :system do
  include_context 'basic Knowledge Base'

  describe 'Link knowledge base answer', authenticated_as: :authenticate do
    include_context 'basic Knowledge Base'

    let(:ticket)      { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:translation) { published_answer.translations.first }

    def authenticate
      translation
      true
    end

    shared_examples 'verify linking' do |elasticsearch:|
      before do
        if elasticsearch
          searchindex_model_reload([KnowledgeBase::Translation, KnowledgeBase::Category::Translation, KnowledgeBase::Answer::Translation])
        end

        visit "#ticket/zoom/#{ticket.id}"
      end

      it 'allows to look up an answer' do
        within :active_content do
          find('.link_kb_answers')

          within '.link_kb_answers' do
            find('.js-add').click

            find('.js-input').send_keys translation.title

            find(%(li[data-value="#{translation.id}"])).click

            expect(find('.link_kb_answers ol')).to have_text translation.title
          end
        end
      end
    end

    context 'with Elasticsearch', searchindex: true do
      include_examples 'verify linking', elasticsearch: true
    end

    context 'without Elasticsearch' do
      include_examples 'verify linking', elasticsearch: false
    end
  end

  describe 'Link an AI-suggested answer via the plus sign', authenticated_as: :authenticate do
    let(:ticket)      { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:translation) { published_answer.translations.first }

    def authenticate
      setup_ai_provider('zammad_ai')

      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
      # The knowledge base answer factory triggers the vector index callback, which must not reach
      # Elasticsearch in this spec.
      allow(Service::AI::VectorDB::Available).to receive(:execute).with(ping: false).and_return(false)
      allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
        .to receive(:execute).and_return({ answers: [{ translation:, score: 0.9 }], pending: false })

      true
    end

    before do
      wait_for_setting('ai_provider', true)

      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'moves the suggested answer into the linked list' do
      within :active_content, '.link_kb_answers' do
        # The AI suggestion is offered with a one-click link (plus) control, and is not linked yet.
        expect(page)
          .to have_css('.js-kb-suggestion-add')
          .and(have_text(translation.title))
          .and(have_no_css('.js-delete'))

        find('.js-kb-suggestion-add').click

        # It became a permanent link (an unlink control appears) and is no longer offered as a suggestion.
        expect(page)
          .to have_css('.js-delete')
          .and(have_text(translation.title))
          .and(have_no_css('.js-kb-suggestion-add'))
      end
    end
  end

  describe 'Generate knowledge base answer from a ticket', authenticated_as: :authenticate do
    let(:ticket)      { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:translation) { published_answer.translations.first }

    let(:pending_search)  { { pending: true } }
    let(:resolved_search) { { answers: [{ translation:, score: 0.88 }], pending: false } }

    # Consecutive return values for the (stubbed) suggestions search; the last one repeats.
    let(:search_results) { [resolved_search] }

    def authenticate
      Setting.set('ai_assistance_kb_answer_from_ticket_generation', true)

      setup_ai_provider('zammad_ai')

      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
      allow(Service::AI::VectorDB::Available).to receive(:execute).with(ping: false).and_return(false)
      allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
        .to receive(:execute).and_return(*search_results)

      true
    end

    before do
      # Force the Knowledge Base into existence up front (some `search_results` stubs below never
      # reference `translation`), otherwise `kb_active` may still be false when the sidebar first
      # renders and `.link_kb_answers` never mounts at all.
      translation

      wait_for_setting('ai_provider', true)
      wait_for_setting('kb_active', true)

      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'shows a confirmation modal listing the suggestions before generating a new draft' do
      within :active_content, '.link_kb_answers' do
        # Only open the modal once the sidebar shows the suggestion, otherwise the assertions below
        # would race the (asynchronous) suggestions search.
        expect(page).to have_text(translation.title)

        find('.js-kb-ai-generate').click
      end

      in_modal do
        expect(page)
          .to have_text('Generate knowledge base answer from this ticket')
          .and(have_text(translation.title))
          .and(have_text(translation.content.body_excerpt))

        # The category/language attributes are always the last '.kb-answer-attributes' block - dates
        # (internally published/published/archived at), when present, render in their own block first.
        within all('.kb-answer-attributes').last do
          expect(page)
            .to have_text(category.translations.first.title)
            .and(have_text(primary_locale.system_locale.name))
        end

        click '.js-submit'
      end

      expect(page).to have_text('A related knowledge base answer is being generated. You will be notified once the draft is ready.')
    end

    context 'when the generation request fails' do
      before do
        allow(TicketAIAssistanceGenerateKnowledgeBaseAnswerJob).to receive(:perform_later).and_return(false)
      end

      it 'keeps the modal open and shows the error in place of the suggestions' do
        within :active_content, '.link_kb_answers' do
          expect(page).to have_text(translation.title)

          find('.js-kb-ai-generate').click
        end

        in_modal disappears: false do
          click '.js-submit'

          expect(page)
            .to have_css('.alert--danger', text: 'Related knowledge base answer creation has already been started for current ticket.')
            .and(have_no_text(translation.title))

          # The error is final, so the draft cannot be requested again from the open modal.
          expect(page).to have_button('Generate', disabled: true)
        end

        expect(page).to have_no_text('A related knowledge base answer is being generated. You will be notified once the draft is ready.')
      end
    end

    context 'when the suggestions search is still running' do
      let(:search_results) { [pending_search] }

      it 'opens the modal and blocks the submit until the search settles' do
        within :active_content, '.link_kb_answers' do
          find('.js-kb-ai-generate').click
        end

        in_modal disappears: false do
          expect(page)
            .to have_text('Searching for related answers…')
            .and(have_button('Generate', disabled: true))
        end
      end
    end

    context 'when the search comes back without results' do
      let(:search_results) { [{ answers: [], pending: false }] }

      it 'shows the empty state and still allows generating a draft' do
        within :active_content, '.link_kb_answers' do
          find('.js-kb-ai-generate').click
        end

        in_modal do
          expect(page).to have_text('No existing knowledge base answers match this topic. Generate a new answer to continue.')

          click '.js-submit'
        end

        expect(page).to have_text('A related knowledge base answer is being generated. You will be notified once the draft is ready.')
      end
    end

    context 'when the search re-runs while the modal is open' do
      let(:other_translation) { published_answer_in_other_category.translations.first }
      let(:search_results) do
        [resolved_search, { answers: [{ translation: other_translation, score: 0.7 }], pending: false }]
      end

      it 'updates the open modal' do
        within :active_content, '.link_kb_answers' do
          expect(page).to have_text(translation.title)

          find('.js-kb-ai-generate').click
        end

        # A new article changes the ticket content, so the widget re-runs the search - the modal is
        # already open at that point and has to follow along instead of keeping its initial list.
        create(:ticket_article, ticket:)

        in_modal disappears: false do
          expect(page)
            .to have_text(other_translation.title)
            .and(have_no_text(translation.title))
        end
      end

      context 'when the re-run is still pending' do
        let(:search_results) { [resolved_search, pending_search] }

        it 'blocks the submit until the search settles' do
          within :active_content, '.link_kb_answers' do
            expect(page).to have_text(translation.title)

            find('.js-kb-ai-generate').click
          end

          create(:ticket_article, ticket:)

          in_modal disappears: false do
            expect(page).to have_text('Searching for related answers…')

            expect(page).to have_button('Generate', disabled: true)
          end
        end
      end
    end
  end

  describe 'displaying knowledge base answer', authenticated_as: :user do
    let(:ticket)               { Ticket.first }
    let(:draft_translation)    { draft_answer.translations.first }
    let(:internal_translation) { internal_answer.translations.first }

    before do
      create(:link, from: ticket, to: draft_answer.translations.first)
      create(:link, from: ticket, to: internal_answer.translations.first)

      visit "#ticket/zoom/#{ticket.id}"
    end

    context 'when user is editor' do
      let(:user) { true }

      it 'shows both linked answers' do
        within '.link_kb_answers' do
          expect(page)
            .to have_text(draft_translation.title)
            .and(have_text(internal_translation.title))
        end
      end
    end

    context 'when user is reader' do
      let(:user) { create(:agent, groups: [ticket.group]) }

      it 'shows accessible answer' do
        within '.link_kb_answers' do
          expect(page)
            .to have_no_text(draft_translation.title)
            .and(have_text(internal_translation.title))
        end
      end
    end
  end
end
