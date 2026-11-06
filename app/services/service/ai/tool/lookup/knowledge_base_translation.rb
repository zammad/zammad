# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Which text of a knowledge base answer a tool reads or links: the one in the locale asked for, as a search or the ticket
#   named it, else the user's, else the knowledge base's primary one, as GraphQL's answer type falls back.
module Service::AI::Tool::Lookup::KnowledgeBaseTranslation
  # @param locale [String, nil] e.g. "de-de"
  # @return [KnowledgeBase::Answer::Translation]
  # @raise [ActiveRecord::RecordNotFound] where the answer has no text at all
  def self.of(answer, locale:, user:)
    knowledge_base = answer.category.knowledge_base
    asked          = locale.presence && knowledge_base.kb_locales.joins(:system_locale).find_by(locales: { locale: })

    answer.translation_preferred(asked || ::KnowledgeBase::Locale.preferred(user, knowledge_base)) || raise(ActiveRecord::RecordNotFound)
  end
end
