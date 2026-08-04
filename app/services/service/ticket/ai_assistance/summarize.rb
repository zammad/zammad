# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::AIAssistance::Summarize < Service::Base

  attr_reader :ticket, :locale, :persistence_strategy, :regeneration_of

  requires_current_user!

  # @param persistence_strategy [Symbol, NilClass] @see Service::AI::Feature#initialize
  def initialize(ticket:, locale: nil, regeneration_of: nil, persistence_strategy: :stored_or_request)
    @ticket               = ticket
    @locale               = locale
    @persistence_strategy = persistence_strategy
    @regeneration_of      = regeneration_of
  end

  def execute
    Service::CheckFeatureEnabled.execute(name: 'ai_assistance_ticket_summary')
    Service::CheckFeatureEnabled.execute(name: 'ai_provider', custom_error_message: __('AI provider is not configured.'))

    return if !Service::Ticket::AIAssistance::SummaryEnabled.with_current_user(current_user).execute(ticket:)
    return if ticket.articles.none?

    articles = ticket.articles.without_system_notifications

    if persistence_strategy != :stored_only
      prepared_articles = Service::AI::Ticket::PreProcessArticleContent
        .execute(
          articles:,
          skip_quotes_strip_first_article: true,
        )
    end

    Service::AI::Feature::TicketSummarize.execute(
      current_user:,
      locale:,
      context_data:         {
        ticket:,
        articles:,
        prepared_articles:,
        config:            summary_config
      },
      persistence_strategy:,
      regeneration_of:
    )
  end

  private

  def summary_config
    @summary_config ||= Setting.get('ai_assistance_ticket_summary_config')
  end
end
