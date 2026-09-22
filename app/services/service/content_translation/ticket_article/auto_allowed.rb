# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Whether a user may have the articles of a whole ticket translated automatically. The admin
# configures it as a toggle and a list of roles; individual-article translation is not affected by
# either.
class Service::ContentTranslation::TicketArticle::AutoAllowed < Service::Base
  attr_reader :user

  # @param user [User]
  def initialize(user:)
    @user = user
  end

  # @return [Boolean]
  def execute
    return false if !Setting.get('content_translation_ticket_article_auto')
    return false if !user.permissions?('ticket.agent')

    in_configured_role?
  end

  private

  # An empty list means every agent, as with `ui_desktop_beta_switch_role_ids`.
  def in_configured_role?
    role_ids = Array(Setting.get('content_translation_ticket_article_auto_role_ids'))

    return true if role_ids.empty?

    role_ids.any? { |role_id| user.role_ids.include?(role_id.to_i) }
  end
end
