# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Summary', authenticated_as: :authenticate, type: :system do
  let(:agent)                        { create(:agent, groups: [ticket.group]) }
  let(:ticket)                       { create(:ticket) }
  let(:article)                      { create(:ticket_article, ticket:) }
  let(:ai_provider)                  { 'zammad_ai' }
  let(:ai_assistance_ticket_summary) { true }
  let(:initial_summary)              { "initial #{Faker::Lorem.unique.sentence}" }
  let(:updated_summary)              { "updated #{Faker::Lorem.unique.sentence}" }
  let(:initial_cache_key)            { "ticket_summary_#{ticket.id}" }
  let(:updated_cache_key)            { "ticket_summary_#{ticket.id}_2" }
  let(:ticket_summary_generation)    { 'on_ticket_detail_opening' }

  let(:initial_content) do
    {
      'customer_request'     => article.body_as_text,
      'conversation_summary' => [initial_summary],
      'open_questions'       => [],
      'upcoming_events'      => [],
      'customer_mood'        => 'Neutral',
      'customer_emotion'     => '😐',
      'language'             => 'en-us',
    }
  end

  let(:updated_content) do
    {
      'customer_request'     => 'Customer is facing an issue with the product.',
      'conversation_summary' => [updated_summary],
      'open_questions'       => ['What is the issue?', 'How can we help?'],
      'upcoming_events'      => ['Next meeting on Friday', 'Follow-up call next week'],
      'customer_mood'        => 'Happy',
      'customer_emotion'     => '🙂',
      'language'             => 'en-us',
    }.compact
  end

  let(:ai_analytics_run) do
    AI::Analytics::Run.create!(
      content:         initial_content,
      version:         AI::Service::TicketSummarize.lookup_version({ articles: ticket.articles.without_system_notifications }, Locale.find_by(locale: agent.locale)),
      ai_service_name: 'TicketSummarize',
      **AI::Service::TicketSummarize.lookup_attributes({ ticket: }, Locale.find_by(locale: agent.locale)),
    )
  end

  def authenticate
    allow(AI::Provider::ZammadAI).to receive(:ping!).and_return(true)

    setup_ai_provider(ai_provider)
    Setting.set('ai_assistance_ticket_summary', ai_assistance_ticket_summary)
    Setting.set('ai_assistance_ticket_summary_config', {
                  open_questions:     true,
                  upcoming_events:    true,
                  customer_sentiment: true,
                  generate_on:        ticket_summary_generation
                })

    article

    agent
  end

  before do
    if defined?(initial_cache_key)
      AI::StoredResult.create!(
        content:          initial_content,
        version:          AI::Service::TicketSummarize.lookup_version({ articles: ticket.articles.without_system_notifications }, Locale.find_by(locale: agent.locale)),
        **AI::Service::TicketSummarize.lookup_attributes({ ticket: }, Locale.find_by(locale: agent.locale)),
        ai_analytics_run:,
      )

      ai_analytics_usage if defined?(ai_analytics_usage)

      allow_any_instance_of(AI::Service::TicketSummarize)
        .to receive(:ask_provider).and_return(updated_content)
    end
  end

  describe 'Sidebar' do
    before { visit "ticket/zoom/#{ticket.id}" }

    context 'when ai_provider is set' do
      before do
        click '.tabsSidebar-tab[data-tab=summary]'
      end

      it 'displays and updates summary in sidebar', performs_jobs: true do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Conversation Summary')
            .and have_text(initial_summary)
        end

        create(:ticket_article, ticket:)

        # This will wait for the job to be enqueued.
        expect(page).to have_text 'Summary is being generated…'

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Conversation Summary')
            .and have_text(updated_summary)
        end
      end

      it 'shows customer intent in the summary sidebar', performs_jobs: true do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Customer Intent')
            .and have_text(article.body_as_text)
        end

        create(:ticket_article, ticket:)

        expect(page).to have_text 'Summary is being generated…'

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Customer Intent')
            .and have_text('Customer is facing an issue with the product.')
        end
      end

      it 'shows open questions in the summary sidebar', performs_jobs: true do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_no_text('Open Questions')
            .and have_no_text('What is the issue?')
            .and have_no_text('How can we help?')
        end

        create(:ticket_article, ticket:)

        expect(page).to have_text 'Summary is being generated…'

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Open Questions')
            .and have_text('What is the issue?')
            .and have_text('How can we help?')
        end
      end

      it 'shows upcoming events in the summary sidebar', performs_jobs: true do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_no_text('Upcoming Events')
            .and have_no_text('Next meeting on Friday')
            .and have_no_text('Follow-up call next week')
        end

        create(:ticket_article, ticket:)

        expect(page).to have_text 'Summary is being generated…'

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Upcoming Events')
            .and have_text('Next meeting on Friday')
            .and have_text('Follow-up call next week')
        end
      end

      it 'shows customer sentiment and emotion in the summary sidebar', performs_jobs: true do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Customer Sentiment')
            .and have_text('Neutral')
            .and have_text('😐')
        end

        create(:ticket_article, ticket:)

        expect(page).to have_text 'Summary is being generated…'

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Customer Sentiment')
            .and have_text('Happy')
            .and have_text('🙂')
        end
      end

    end

    context 'when summary feature is disabled' do
      let(:ai_assistance_ticket_summary) { false }

      it 'does not show sidebar' do
        expect(page).to have_text(ticket.title)
          .and have_no_css('.tabsSidebar-tab[data-tab=summary]')
      end
    end
  end

  describe 'Indicator', performs_jobs: true do
    before { visit "ticket/zoom/#{ticket.id}" }

    context 'when summary was updated before opening the tab' do
      it 'dot is visible but gone after looking at the sidebar' do
        expect(page).to have_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')

        click '.tabsSidebar-tab[data-tab=summary]'

        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')

        refresh

        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')
      end

      it 'dot is visible when summary is updated while looking at other tab' do
        click '.tabsSidebar-tab[data-tab=summary]'
        click '.tabsSidebar-tab[data-tab=customer]'

        create(:ticket_article, ticket:)

        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')

        wait.until do
          enqueued_jobs.any? { |job| job[:job] == TicketAIAssistanceSummarizeJob }
        end

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        expect(page).to have_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')
      end

      it 'dot is not visible when summary is updated while looking at the summary tab' do
        click '.tabsSidebar-tab[data-tab=summary]'

        create(:ticket_article, ticket:)

        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')

        wait.until do
          enqueued_jobs.any? { |job| job[:job] == TicketAIAssistanceSummarizeJob }
        end

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text updated_summary
        end

        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')
      end

      it 'dot is not visible when summary is updated by myself' do
        click '.tabsSidebar-tab[data-tab=summary]'
        click '.tabsSidebar-tab[data-tab=customer]'

        create(:ticket_article, ticket:, origin_by: agent)

        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')

        wait.until do
          enqueued_jobs.any? { |job| job[:job] == TicketAIAssistanceSummarizeJob }
        end

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')

        click '.tabsSidebar-tab[data-tab=summary]'
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text updated_summary
        end

        expect(page).to have_no_css('.tabsSidebar-tab[data-tab=summary] .tabsSidebar-tab-dot')
      end
    end
  end

  describe 'Requesting a summary' do
    let(:other_ticket) { create(:ticket, group: ticket.group) }

    context 'when requesting on opening a ticket' do
      it 'makes a request for a summary on opening a ticket' do
        # Create multiple taskbars
        visit "ticket/zoom/#{ticket.id}"
        visit "ticket/zoom/#{other_ticket.id}"

        visit '#dashboard'

        # Reload the app to ensure the summary subscriptions are not set up
        refresh

        allow(Service::Ticket::AIAssistance::Summarize).to receive(:new).and_call_original

        visit "ticket/zoom/#{ticket.id}"

        within :active_content do
          expect(page).to have_text ticket.title
        end

        # Expect exactly once, this checks if non-active taskbar is not subscribing on app load
        expect(Service::Ticket::AIAssistance::Summarize).to have_received(:new).once
      end
    end

    context 'when requesting on opening a sidebar' do
      let(:ticket_summary_generation) { 'on_ticket_summary_sidebar_activation' }

      it 'makes a request for a summary on clicking on sidebar' do
        visit '#dashboard'

        allow(Service::Ticket::AIAssistance::Summarize).to receive(:new).and_call_original

        visit "ticket/zoom/#{ticket.id}"

        expect(page).to have_text ticket.title

        expect(Service::Ticket::AIAssistance::Summarize).not_to have_received(:new)

        click '.tabsSidebar-tab[data-tab=summary]'

        expect(Service::Ticket::AIAssistance::Summarize).to have_received(:new).once
      end
    end

    context 'when group generation setting is configured' do
      let(:ticket_summary_generation) { 'on_ticket_detail_opening' }

      before do
        ticket.group.update!(summary_generation: 'on_ticket_summary_sidebar_activation')
      end

      it 'uses the group setting over the default' do
        visit '#dashboard'

        allow(Service::Ticket::AIAssistance::Summarize).to receive(:new).and_call_original

        visit "ticket/zoom/#{ticket.id}"

        expect(page).to have_text ticket.title

        expect(Service::Ticket::AIAssistance::Summarize).not_to have_received(:new)

        click '.tabsSidebar-tab[data-tab=summary]'

        expect(Service::Ticket::AIAssistance::Summarize).to have_received(:new).once
      end
    end
  end

  describe 'Analytics' do
    before do |example|
      visit "ticket/zoom/#{ticket.id}"

      click '.tabsSidebar-tab[data-tab=summary]' if !example.metadata[:do_not_click_summary_tab]
    end

    context 'when the usage has not been recorded yet' do
      it 'records usage when switching to summary tab', do_not_click_summary_tab: true do
        expect(ai_analytics_run.usages.find_by(user: agent)).to be_nil

        click '.tabsSidebar-tab[data-tab=summary]'

        expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
          rating: nil,
        )
      end

      it 'records positive feedback when giving thumbs up' do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Any feedback on this result?')
            .and have_no_text('Thank you for your feedback.')

          click '.js-aiPositiveReaction'

          expect(page).to have_no_text('Any feedback on this result?')
            .and have_text('Thank you for your feedback.')
            .and have_no_css('.js-aiFeedbackButtons')
            .and have_css('.js-aiRegenerate')
            .and have_no_css('.js-aiCommentField')
        end

        expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
          rating: true,
        )
      end

      it 'records negative feedback when giving thumbs down (w/ optional comment)' do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Any feedback on this result?')
            .and have_no_text('Thank you for your feedback.')

          click '.js-aiNegativeReaction'

          expect(page).to have_no_text('Any feedback on this result?')
            .and have_field('comment', placeholder: 'Thanks for the feedback. Please explain what went wrong?')
            .and have_no_css('.js-aiFeedbackToolbar')
        end

        expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
          rating: false,
        )

        within '.sidebar[data-tab="summary"]' do
          fill_in 'comment', with: 'bad bot'
          click '.js-aiCommentSubmit'

          expect(page).to have_text('Thank you for your feedback.')
            .and have_no_css('.js-aiCommentField')
            .and have_css('.js-aiRegenerate')
        end

        expect(ai_analytics_run.usages.find_by(user: agent)).to have_attributes(
          rating:  false,
          comment: 'bad bot',
        )
      end
    end

    context 'when the usage has been already recorded' do
      let(:ai_analytics_usage) { create(:ai_analytics_usage, ai_analytics_run:, user: agent, rating: nil) }

      it 'does not record usage again when switching to summary tab', do_not_click_summary_tab: true do
        expect { click '.tabsSidebar-tab[data-tab=summary]' }.not_to change(ai_analytics_usage, :updated_at)
      end

      it 'renders feedback buttons' do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_css('.js-aiFeedbackButtons')
            .and have_css('.js-aiRegenerate')
            .and have_text('Any feedback on this result?')
            .and have_no_text('Thank you for your feedback.')
            .and have_no_text('You have already provided feedback, thank you.')
        end

      end

      context 'when user has already provided feedback' do
        let(:ai_analytics_usage) { create(:ai_analytics_usage, ai_analytics_run:, user: agent, rating: true) }

        it 'does not render feedback buttons' do
          within '.sidebar[data-tab="summary"]' do
            expect(page).to have_no_css('.js-aiFeedbackButtons')
              .and have_css('.js-aiRegenerate')
              .and have_no_text('Any feedback on this result?')
              .and have_text('You have already provided feedback, thank you.')
          end
        end
      end
    end

    context 'when regenerating the summary', performs_jobs: true do
      it 'shows new summary' do
        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text('Conversation Summary')
            .and have_text(initial_summary)

          click '.js-aiRegenerate'

          # This will wait for the job to be enqueued.
          expect(page).to have_text('Summary is being generated…')
        end

        perform_enqueued_jobs(only: TicketAIAssistanceSummarizeJob)

        within '.sidebar[data-tab="summary"]' do
          expect(page).to have_text(updated_summary)
        end
      end
    end
  end
end
