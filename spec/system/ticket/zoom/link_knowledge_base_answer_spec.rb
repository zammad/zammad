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
        # Its relevance score is shown, because the current user is an administrator.
        expect(page)
          .to have_css('.js-kb-suggestion-add')
          .and(have_text(translation.title))
          .and(have_text('90%'))
          .and(have_no_css('.js-delete'))

        find('.js-kb-suggestion-add').click

        # It became a permanent link (an unlink control appears) and is no longer offered as a suggestion.
        expect(page)
          .to have_css('.js-delete')
          .and(have_text(translation.title))
          .and(have_no_css('.js-kb-suggestion-add'))
      end
    end

    it 'offers the answer as a suggestion again after unlinking it' do
      within :active_content, '.link_kb_answers' do
        find('.js-kb-suggestion-add').click

        expect(page).to have_css('.js-delete').and(have_no_css('.js-kb-suggestion-add'))

        find('.js-delete').click

        # Linking dropped the answer from the suggestions locally, so it can only come back by
        #   re-running the search once the link is gone.
        expect(page)
          .to have_css('.js-kb-suggestion-add')
          .and(have_text(translation.title))
          .and(have_no_css('.js-delete'))
      end
    end
  end

  describe 'AI suggestions with no results', authenticated_as: :authenticate do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      setup_ai_provider('zammad_ai')

      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
      # The knowledge base answer factory triggers the vector index callback, which must not reach
      # Elasticsearch in this spec.
      allow(Service::AI::VectorDB::Available).to receive(:execute).with(ping: false).and_return(false)
      allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
        .to receive(:execute).and_return({ answers: [], pending: false })

      true
    end

    before do
      # Force the Knowledge Base into existence up front, otherwise `kb_active` may still be false
      # when the sidebar first renders and `.link_kb_answers` never mounts at all.
      knowledge_base

      wait_for_setting('ai_provider', true)
      wait_for_setting('kb_active', true)

      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'shows an empty state message in the sidebar' do
      within :active_content, '.link_kb_answers' do
        expect(page).to have_text('No suggestions.')
      end
    end
  end

  describe 'AI-suggested answers without knowledge base permission', authenticated_as: :authenticate do
    let(:ticket)      { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:translation) { published_answer.translations.first }
    let(:agent)       { create(:agent, roles: [create(:role, permission_names: %w[ticket.agent])], groups: [ticket.group]) }

    def authenticate
      setup_ai_provider('zammad_ai')

      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
      # The knowledge base answer factory triggers the vector index callback, which must not reach
      # Elasticsearch in this spec.
      allow(Service::AI::VectorDB::Available).to receive(:execute).with(ping: false).and_return(false)
      # Only published answers are suggested to them, which the search itself takes care of.
      allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers)
        .to receive(:execute).and_return({ answers: [{ translation:, score: 0.9 }], pending: false })

      agent
    end

    before do
      wait_for_setting('ai_provider', true)
      wait_for_setting('kb_active', true)

      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'shows the suggestion, linked to its public page' do
      within :active_content, '.link_kb_answers' do
        expect(page)
          .to have_link(translation.title, href: %r{/help/#{locale_name}/#{category.id}/#{published_answer.id}$}, target: '_blank')
          .and(have_css('.kb-answer-external-icon'))
          # The relevance score is only shown to AI administrators.
          .and(have_no_text('90%'))
      end
    end
  end

  describe 'Generate knowledge base answer from a ticket', authenticated_as: :authenticate do
    let(:ticket)      { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:translation) { published_answer.translations.first }

    let(:pending_search)  { { pending: true } }
    let(:resolved_search) { { answers: [{ translation:, score: 0.88 }], pending: false } }

    # What the (stubbed) suggestions search currently returns. The sidebar list and the modal each run
    # their own search, so the result is held rather than queued - a test changes it to make the next
    # search of either scope come back differently.
    let(:search_result)       { resolved_search }
    let(:current_search)      { { result: search_result } }
    let(:suggestions_enabled) { true }

    # The widening flags of every search, in call order: only the modal's search covers drafts and
    # archived answers, and only it keeps the answers already linked to the ticket.
    let(:requested_drafts_and_archived) { [] }
    let(:requested_linked_answers)      { [] }

    def authenticate
      setup_ai_provider('zammad_ai')
      Setting.set('ai_assistance_kb_answer_suggestions', suggestions_enabled)

      allow(Service::AI::VectorDB::Available).to receive(:execute).and_return(true)
      allow(Service::AI::VectorDB::Available).to receive(:execute).with(ping: false).and_return(false)
      allow(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).to receive(:execute) do |**args|
        requested_drafts_and_archived << args[:include_drafts_and_archived]
        requested_linked_answers << args[:include_linked_answers]
        current_search[:result]
      end

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

    # Whether an answer already covers the ticket is also answered by an unfinished or a retired one,
    # so the modal searches wider than the sidebar list.
    it 'lists draft answers, with their state, in the modal' do
      draft_translation = draft_answer.translations.first

      within :active_content, '.link_kb_answers' do
        expect(page).to have_text(translation.title)

        # The sidebar list offers answers to work with, so it searches the internally visible ones
        #   that are not linked yet.
        expect(requested_drafts_and_archived).to eq([false])
        expect(requested_linked_answers).to eq([false])

        current_search[:result] = { answers: [{ translation: draft_translation, score: 0.9 }], pending: false }

        find('.js-kb-ai-generate').click
      end

      in_modal do
        expect(page)
          .to have_text(draft_translation.title)
          .and(have_css('.state-draft', text: 'draft'))

        click '.js-cancel'
      end

      expect(requested_drafts_and_archived).to include(true)
      expect(requested_linked_answers).to include(true)

      # Each scope keeps its own result: the draft belongs to the modal's wider search only.
      within :active_content, '.link_kb_answers' do
        expect(page)
          .to have_text(translation.title)
          .and(have_no_text(draft_translation.title))
      end
    end

    # A reopened modal has to reflect the ticket as it is now. That its previous answers are also
    # gone from the moment it opens (rather than lingering, confirmable with "Generate", until the
    # fresh search lands) is not assertable from here: Capybara waits for the request to settle after
    # the click, so it only ever observes the state afterwards.
    it 'searches again for the modal when the ticket changed while it was closed' do
      other_translation = published_answer_in_other_category.translations.first

      within :active_content, '.link_kb_answers' do
        expect(page).to have_text(translation.title)

        find('.js-kb-ai-generate').click
      end

      in_modal do
        expect(page).to have_text(translation.title)

        click '.js-cancel'
      end

      current_search[:result] = { answers: [{ translation: other_translation, score: 0.7 }], pending: false }

      create(:ticket_article, ticket:)

      within :active_content, '.link_kb_answers' do
        # The sidebar list is on screen, so it re-runs the search right away - by the time its new
        # result is up, the closed modal has been invalidated as well.
        expect(page).to have_text(other_translation.title)

        find('.js-kb-ai-generate').click
      end

      in_modal disappears: false do
        expect(page)
          .to have_text(other_translation.title)
          .and(have_no_text(translation.title))
      end
    end

    # Generating a draft adds an answer without changing the ticket, so nothing invalidates the
    # modal's result - it has to search again on its own, or reopening keeps showing the answers (or
    # the empty state) from before the generation.
    it 'searches again whenever the modal is reopened' do
      current_search[:result] = { answers: [], pending: false }

      within :active_content, '.link_kb_answers' do
        find('.js-kb-ai-generate').click
      end

      in_modal do
        expect(page).to have_text('No existing knowledge base answers match this topic.')

        click '.js-cancel'
      end

      # What the generated draft looks like to the next search of the modal.
      current_search[:result] = resolved_search

      within :active_content, '.link_kb_answers' do
        find('.js-kb-ai-generate').click
      end

      in_modal disappears: false do
        expect(page).to have_text(translation.title)
      end
    end

    # The embed job's failure ping arrives while the modal is closed, so nobody is there to show it -
    # reopening has to search again instead of waiting on a request it will never issue.
    it 'searches again when the modal is reopened after a failed embedding' do
      current_search[:result] = pending_search

      within :active_content, '.link_kb_answers' do
        find('.js-kb-ai-generate').click
      end

      in_modal do
        expect(page).to have_text('Searching for related answers…')

        click '.js-cancel'
      end

      Service::Ticket::AI::RelatedKnowledgeBaseAnswers.broadcast_error(ticket, 'embedding failed')

      current_search[:result] = resolved_search

      within :active_content, '.link_kb_answers' do
        # The sidebar list is on screen, so it shows the failure - and its arrival is what makes the
        # reopened modal below search again.
        expect(page).to have_text('The suggestions could not be generated.')

        find('.js-kb-ai-generate').click
      end

      in_modal disappears: false do
        expect(page).to have_text(translation.title)
      end
    end

    context 'when suggestions in the ticket sidebar are disabled' do
      let(:suggestions_enabled) { false }

      it 'still checks for duplicate answers in the generation modal' do
        within :active_content, '.link_kb_answers' do
          expect(page).to have_no_text('Suggested by AI')
          expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).not_to have_received(:execute)

          find('.js-kb-ai-generate').click
        end

        in_modal do
          expect(page)
            .to have_text('Generate knowledge base answer from this ticket')
            .and(have_text(translation.title))
            .and(have_text(translation.content.body_excerpt))
        end

        expect(Service::Ticket::AI::RelatedKnowledgeBaseAnswers).to have_received(:execute).once
      end
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
      let(:search_result) { pending_search }

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
      let(:search_result) { { answers: [], pending: false } }

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
      let(:rerun_search)      { { answers: [{ translation: other_translation, score: 0.7 }], pending: false } }

      it 'updates the open modal' do
        within :active_content, '.link_kb_answers' do
          expect(page).to have_text(translation.title)

          find('.js-kb-ai-generate').click
        end

        in_modal disappears: false do
          expect(page).to have_text(translation.title)
        end

        current_search[:result] = rerun_search

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
        let(:rerun_search) { pending_search }

        it 'blocks the submit until the search settles' do
          within :active_content, '.link_kb_answers' do
            expect(page).to have_text(translation.title)

            find('.js-kb-ai-generate').click
          end

          in_modal disappears: false do
            expect(page).to have_text(translation.title)
          end

          current_search[:result] = rerun_search

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
    let(:ticket)                { Ticket.first }
    let(:draft_translation)     { draft_answer.translations.first }
    let(:internal_translation)  { internal_answer.translations.first }
    let(:published_translation) { published_answer.translations.first }

    before do
      create(:link, from: ticket, to: draft_answer.translations.first)
      create(:link, from: ticket, to: internal_answer.translations.first)
      create(:link, from: ticket, to: published_answer.translations.first)

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
            .and(have_link(internal_translation.title, href: %r{#knowledge_base/}))
            .and(have_no_css('.kb-answer-external-icon'))
        end
      end
    end

    context 'when user has no knowledge base permission' do
      let(:user) { create(:agent, roles: [create(:role, permission_names: %w[ticket.agent])], groups: [ticket.group]) }

      it 'shows the published answer only, linked to its public page' do
        within '.link_kb_answers' do
          expect(page)
            .to have_no_text(draft_translation.title)
            .and(have_no_text(internal_translation.title))
            .and(have_link(published_translation.title, href: %r{/help/#{locale_name}/#{category.id}/#{published_answer.id}$}, target: '_blank'))
            .and(have_css('.kb-answer-external-icon'))
        end
      end
    end
  end
end
