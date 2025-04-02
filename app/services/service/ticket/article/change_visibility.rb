# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::ChangeVisibility < Service::BaseWithCurrentUser
  def execute(article:, internal:)
    Pundit.authorize current_user, article, :update?

    article.update! internal: internal

    article
  end
end
