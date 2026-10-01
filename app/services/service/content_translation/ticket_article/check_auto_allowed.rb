# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Raises unless the user may have the articles of a whole ticket translated automatically, see
# Service::ContentTranslation::TicketArticle::AutoAllowed.
class Service::ContentTranslation::TicketArticle::CheckAutoAllowed < Service::Base
  attr_reader :user

  # @param user [User]
  def initialize(user:)
    @user = user
  end

  def execute
    return if Service::ContentTranslation::TicketArticle::AutoAllowed.execute(user:)

    raise Exceptions::Forbidden, __('Automatic translation of ticket articles is not available for you.')
  end
end
