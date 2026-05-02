# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::AIAssistance::Summarize < Service::Base

  attr_reader :ticket, :locale, :persistence_strategy, :regeneration_of

  # @param persistence_strategy [Symbol, NilClass] @see AI::Service#initialize
  def initialize(ticket:, locale: nil, regeneration_of: nil, persistence_strategy: :stored_or_request)
    @ticket               = ticket
    @locale               = locale
    @persistence_strategy = persistence_strategy
    @regeneration_of      = regeneration_of
  end

  def execute
    Service::CheckFeatureEnabled.execute(name: 'ai_assistance_ticket_summary')
    Service::CheckFeatureEnabled.execute(name: 'ai_provider', custom_error_message: __('AI provider is not configured.'))

    return if ticket.articles.none?

    articles = ticket.articles.without_system_notifications

    if persistence_strategy != :stored_only
      prepared_articles = Service::AI::Ticket::PreProcessArticleContent.execute(articles:, skip_quotes_strip_first_article: true)
    end

    summarize = AI::Service::TicketSummarize.new(
      current_user:,
      locale:,
      context_data:         {
        ticket:,
        articles:,
        prepared_articles:,
        config:            Setting.get('ai_assistance_ticket_summary_config')
      },
      persistence_strategy:,
      regeneration_of:
    )

    summarize.execute
  end
end
