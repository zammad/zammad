# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::MentionsControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    # The mention/subscriber list is agent-only. Returning the full mention list
    # to customers would expose other participants and subscriber assets.
    return false if !record.mentionable_object

    TicketPolicy.new(user, record.mentionable_object).agent_read_access?
  end

  def create?
    return false if !record.mentionable_object

    if record.params[:user_id].present? && record.params[:user_id].to_i != user.id
      # Agent-Add-Other: requires feature flag + identical gate as GraphQL ParticipantAdd
      return false if !Setting.get('ticket_participants_enabled')
      TicketPolicy.new(user, record.mentionable_object).agent_update_access?
    else
      # Self-Subscribe (unverändert, works with flag off): G1-Guard via object_accessible?
      object_accessible?
    end
  end

  def destroy?
    mention = Mention.find_by(id: record.params[:id])
    return false if !mention

    # Self-removal: the mentioned user can always remove themselves
    return true if mention.user_id == user.id

    # Agent-removal: requires the feature flag, agent update access, and a non-agent
    # participant target (preserve agent @mentions/subscriptions).
    return false if !Setting.get('ticket_participants_enabled')
    return false if mention.user.permissions?('ticket.agent')

    if mention.mentionable_type == 'Ticket'
      ticket = Ticket.find_by(id: mention.mentionable_id)
      return true if ticket && TicketPolicy.new(user, ticket).agent_update_access?
    end

    false
  end

  private

  def object_accessible?
    return false if !Mention.mentionable?(record.mentionable_object, user)

    # Self-subscribe guard (G1): customer may only subscribe to tickets they can see
    if user.permissions?('ticket.customer') && !TicketPolicy.new(user, record.mentionable_object).show?
      return false
    end

    true
  rescue Exceptions::UnprocessableContent => e
    not_authorized(e)
  end

  def mentioned_user?
    mention = Mention.find_by id: record.params[:id]

    mention&.user_id == user.id
  end
end
