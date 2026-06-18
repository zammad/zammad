# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::MentionsControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    object_accessible?
  end

  def create?
    if record.params[:user_id].present? && record.params[:user_id].to_i != user.id
      # Agent-Add-Other: identisches Gate wie GraphQL ParticipantAdd (agent_update_access?)
      TicketPolicy.new(user, record.mentionable_object).agent_update_access?
    else
      # Self-Subscribe (unverändert): G1-Guard via object_accessible?
      object_accessible?
    end
  end

  def destroy?
    mention = Mention.find_by(id: record.params[:id])
    return false if !mention

    # Self-removal: the mentioned user can always remove themselves
    return true if mention.user_id == user.id

    # Agent-removal: agent with update access can remove any participant
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
    if user.permissions?('ticket.customer')
      return false if !TicketPolicy.new(user, record.mentionable_object).show?
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
