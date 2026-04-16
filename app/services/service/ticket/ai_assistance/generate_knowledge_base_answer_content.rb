# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::AIAssistance::GenerateKnowledgeBaseAnswerContent < Service::BaseWithCurrentUser
  attr_reader :ticket, :locale, :category_options

  def initialize(ticket:, current_user:, locale: nil, category_options: [])
    super(current_user:)

    @ticket           = ticket
    @locale           = locale
    @category_options = category_options
  end

  def execute
    Service::CheckFeatureEnabled.new(name: 'ai_provider', custom_error_message: __('AI provider is not configured.')).execute

    return nil if ticket.articles.none?

    articles = ticket.articles.without_system_notifications
    prepared_articles = Service::AI::Ticket::PreProcessArticleContent.new(articles:, skip_quotes_strip_first_article: true).execute

    generator = AI::Service::KnowledgeBaseAnswerFromTicket.new(
      current_user:,
      locale:,
      context_data: {
        ticket:,
        articles:,
        prepared_articles:,
        category_options:
      }
    )

    generator.execute
  end
end
