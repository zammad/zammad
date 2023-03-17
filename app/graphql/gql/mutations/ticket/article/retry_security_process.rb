# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::RetrySecurityProcess < BaseMutation
    description "Retry an article's security process."

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, description: 'Retry the security process for this article.'

    field :retry_result, Gql::Types::Ticket::Article::SecurityStateType, description: 'Result of the operation.'
    field :article, Gql::Types::Ticket::ArticleType, description: 'Updated article (article is not updated in case of an error result).'

    def self.authorize(_obj, ctx)
      ctx[:current_user].permissions?(['ticket.agent'])
    end

    def authorized?(article:)
      Pundit.authorize(context.current_user, article, :update?)
    end

    def resolve(article:)
      { retry_result: SecureMailing.retry(article)&.first, article: article.reload }
    end
  end
end
