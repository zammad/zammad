# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Loads the stored translations of the articles of one page in one query, so a list of articles
# does not ask the store once per article.
class Gql::Loaders::Ticket::ArticleTranslationLoader < GraphQL::Batch::Loader
  # @param target_locale [String] locale code, e.g. "de-de"
  def initialize(target_locale, with_content: false)
    super()
    @target_locale = target_locale
    @with_content = with_content
  end

  def perform(articles)
    stored = Service::ContentTranslation::TicketArticle
      .stored_translations(articles, @target_locale)
    stored = stored.select(:content) if @with_content
    stored = stored.index_by(&:related_object_id)

    articles.each do |article|
      translation = stored[article.id]
      if @with_content && translation
        translation = Service::ContentTranslation::TicketArticle.for_display(
          article,
          { content: translation.content, backend: translation.metadata['backend'], translated: true }
        )
      end
      fulfill(article, translation)
    end
  end
end
