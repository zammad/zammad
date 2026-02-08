# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::Article::RetryMediaDownload < BaseMutation
    description "Retry an article's media download."

    argument :article_id, GraphQL::Types::ID, loads: Gql::Types::Ticket::ArticleType, loads_pundit_method: :update?, description: 'Retry the security process for this article.'

    field :success, Boolean, description: 'Was the operation successful?'
    field :article, Gql::Types::Ticket::ArticleType, description: 'Updated article (article is not updated in case of an error result).'

    requires_permission 'ticket.agent'

    def resolve(article:)
      Whatsapp::Retry::Media.new(article:).process

      { success: true, article: article.reload }
    rescue Whatsapp::Retry::Media::ArticleInvalidError, Whatsapp::Client::CloudAPIError => e
      error_response({ message: e.message })
    end
  end
end
