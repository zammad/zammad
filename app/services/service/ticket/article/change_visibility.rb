# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Article::ChangeVisibility < Service::Base
  requires_current_user!

  attr_reader :article, :internal

  def initialize(article:, internal:)
    @article = article
    @internal = internal
  end

  def execute
    Pundit.authorize current_user, article, :update?

    article.update! internal: internal

    article
  end
end
