# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::RetrySecurityProcess < BaseMutation
    description "Retry an article's security process."

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, loads_pundit_method: :update?, description: 'Retry the security process for this article.'

    field :retry_result, Gql::Types::Ticket::Article::SecurityStateType, description: 'Result of the operation.'
    field :article, Gql::Types::Ticket::ArticleType, description: 'Updated article (article is not updated in case of an error result).'

    requires_permission 'ticket.agent'

    def resolve(article:)
      { retry_result: SecureMailing.retry(article)&.first, article: article.reload }
    end
  end
end
