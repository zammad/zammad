# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Which shared draft a tool reads or sends: the ticket's, as the interface shows it, and what it would change besides
#   the message.
module Service::AI::Tool::Lookup::SharedDraft
  # Where the group has shared drafts and the user may see the draft, as its policy decides.
  #
  # @return [Ticket::SharedDraftZoom, nil]
  def self.of(ticket, user:)
    draft = ticket.shared_draft
    return if draft.nil? || !ticket.group.shared_drafts

    draft if Pundit.policy(user, draft).show?
  end

  # The ticket fields the draft holds another value for than the ticket has. Both interfaces keep the whole ticket form
  #   in a draft, changed or not; a key that is no ticket field is form state.
  #
  # @return [Array<String>]
  def self.changed_fields(draft)
    ticket = draft.ticket

    draft.ticket_attributes.to_h.filter_map do |name, value|
      name = name.to_s
      # The desktop form carries the ticket's GraphQL ID as id, which no draft changes.
      next if name == 'id' || !ticket.has_attribute?(name)

      # Both forms keep nobody as an empty owner and send it as the system user.
      value = Service::EntityAttribute::NameMatch::NOBODY_ID if name == 'owner_id' && value.blank?

      name if comparable(::Ticket.type_for_attribute(name).cast(value)) != comparable(ticket[name])
    end
  end

  # Whether the agent chose to sign or encrypt the email, as the desktop form keeps it (security options) or the legacy
  #   one (the preferences an article gets); only Zammad sends it so.
  def self.secured?(draft)
    article = draft.new_article.with_indifferent_access

    Array(article.dig(:security, :options)).any? ||
      %w[sign encryption].any? { |kind| article.dig(:preferences, :security, kind, :success) }
  end

  # A time to the second, as the forms send it; an empty value as none.
  def self.comparable(value)
    return value.to_i if value.is_a?(Time) || value.is_a?(ActiveSupport::TimeWithZone)

    value.presence
  end
  private_class_method :comparable
end
