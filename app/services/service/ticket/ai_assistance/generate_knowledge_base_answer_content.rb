# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent < Service::Base
  requires_current_user!
  attr_reader :ticket, :locale, :category_options

  def initialize(ticket:, locale: nil, category_options: [])
    @ticket           = ticket
    @locale           = locale
    @category_options = category_options
  end

  def execute
    Service::CheckFeatureEnabled.execute(name: 'ai_provider', custom_error_message: __('AI provider is not configured.'))

    return nil if ticket.articles.none?

    articles = ticket.articles.without_system_notifications

    prepared_articles = Service::AI::Ticket::PreProcessArticleContent
      .execute(
        articles:,
        skip_quotes_strip_first_article: true,
      )

    Service::AI::Feature::KnowledgeBaseAnswerFromTicket.execute(
      current_user:,
      locale:,
      context_data: {
        ticket:,
        articles:,
        prepared_articles:,
        category_options:
      }
    )
  end
end
