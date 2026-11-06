# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A ticket in a list a tool returns, such as a search's hits or an overview's tickets: its row with its times, and the
#   start of its first message below it, so that the model meets every list's tickets in one form.
class Service::AI::Tool::Output::ListedTicket < Service::AI::Tool::Output
  EXCERPT_LENGTH = 200

  TIME = { type: 'string', format: 'date-time' }.freeze

  class << self
    # @param properties [Hash] the schemas of the list's own facts in the row
    def schema(**properties)
      Service::AI::Tool::Output::Ticket.schema(
        created_at: TIME,
        updated_at: TIME,
        excerpt:    Service::AI::Tool::Output::Message::SCHEMA.merge(description: 'The start of the ticket\'s first message, with response_format "detailed".'), # rubocop:disable Zammad/DetectTranslatableString
        **properties,
      )
    end

    # The first message of each ticket the user may see, for a whole page at once.
    #
    # @return [Hash{Integer => Ticket::Article}] by ticket ID
    def first_articles(tickets, user:)
      # The policy reads the group of each ticket.
      ActiveRecord::Associations::Preloader.new(records: tickets, associations: :group).call
      with_internal, public_only = tickets.partition { |ticket| TicketPolicy.new(user, ticket).agent_read_access? }
      ids = first_article_ids(with_internal) + first_article_ids(public_only, internal: false)

      ::Ticket::Article.where(id: ids).includes(:sender, :type, :created_by, :origin_by).index_by(&:ticket_id)
    end

    # @param article [Ticket::Article, nil] the ticket's first message, from first_articles
    # @param content [Hash] the list's own facts for the content
    # @param facts [Array<String>] the same facts for the line
    def row(ticket, article:, content: {}, facts: [])
      excerpt = excerpt_of(article)
      row     = Service::AI::Tool::Output::Ticket.row(
        ticket,
        content: { created_at: ticket.created_at, updated_at: ticket.updated_at, excerpt: excerpt&.content, **content }.compact,
        facts:   ["created #{time(ticket.created_at)}", "updated #{time(ticket.updated_at)}", *facts],
      )

      row.with(text: [row.text, excerpt&.text].compact.join("\n"))
    end

    private

    def first_article_ids(tickets, internal: true)
      return [] if tickets.empty?

      articles = ::Ticket::Article.where(ticket_id: tickets.map(&:id)).without_system_notifications
      articles = articles.where(internal: false) if !internal
      articles.group(:ticket_id).minimum(:id).values
    end

    # The start of the first message, cleaned as get_ticket cleans it.
    def excerpt_of(article)
      return if article.nil?

      cleaned = Service::AI::Ticket::PreProcessArticleContent
        .execute(articles: [article], skip_quotes_strip_first_article: true, skip_ocr: true)
        .first[:text].to_s.squish

      Service::AI::Tool::Output::Message.part(article, position: 1, text: cleaned, length: EXCERPT_LENGTH, excerpt: true)
    end
  end
end
