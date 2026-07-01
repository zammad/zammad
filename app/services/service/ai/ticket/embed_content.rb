# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Ticket::EmbedContent < Service::AI::Ticket::EmbedBase

  # Prepares the ticket content (title + article bodies), cleans it up, checks that it fits
  # within the embedding model's context window, and returns the embedding vector.
  #
  # @return [Array<Numeric>] embedding vector for the ticket content
  def execute
    input = build_content
    check_content_size!(input)
    Service::AI::VectorDB::Embedding.execute(input:)
  end

  private

  def build_content
    parts = [ticket.title]

    parts << Service::AI::Ticket::PreProcessArticleContent
               .execute(articles: ticket.articles.without_system_notifications, skip_quotes_strip_first_article: true, skip_ocr: true, link_style: :plain)
               .pluck(:text)

    parts.join("\n\n")
  end
end
