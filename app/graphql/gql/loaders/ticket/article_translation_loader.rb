# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Loads the stored translations of the articles of one page in one query, so a list of articles
# does not ask the store once per article.
class Gql::Loaders::Ticket::ArticleTranslationLoader < GraphQL::Batch::Loader
  # @param target_locale [String] locale code, e.g. "de-de"
  def initialize(target_locale)
    super()
    @target_locale = target_locale
  end

  def perform(articles)
    stored = Service::ContentTranslation::TicketArticle
      .stored_translations(articles, @target_locale)
      .index_by(&:related_object_id)

    articles.each { |article| fulfill(article, stored[article.id]) }
  end
end
