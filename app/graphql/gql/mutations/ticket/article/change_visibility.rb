# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::ChangeVisibility < BaseMutation
    description 'Change ticket article visibility from public to internal or vice versa'

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, description: 'The article to be updated'
    argument :internal, Boolean, description: 'Target visibility'

    field :article, Gql::Types::Ticket::ArticleType, description: 'The updated ticket article'

    def resolve(article:, internal:)
      article = Service::Ticket::Article::ChangeVisibility
        .new(current_user: context.current_user)
        .execute(article: article, internal: internal)

      { article: article }
    end
  end
end
