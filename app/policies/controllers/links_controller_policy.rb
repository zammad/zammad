# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::LinksControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    object_show?
  end

  def add?
    object_target_update? && object_source_show?
  end

  def remove?
    object_target_update?
  end

  private

  def object_show?
    policy = object_policy(record.params[:link_object], id: record.params[:link_object_value])

    object_access?(policy, :agent_read_access?)
  rescue ActiveRecord::RecordNotFound, NoMatchingPatternError
    # A missing or unsupported object must deny like an unauthorized one. Letting the
    #   404 through would turn the endpoint into an existence oracle for every ticket id.
    false
  end

  def object_target_update?
    policy = object_policy(record.params[:link_object_target], id: record.params[:link_object_target_value])

    object_access?(policy, :agent_update_access?)
  end

  def object_source_show?
    policy = object_policy(record.params[:link_object_source], number: record.params[:link_object_source_number])

    object_access?(policy, :agent_read_access?)
  end

  def object_access?(policy, ticket_access)
    case policy
    when TicketPolicy
      policy.public_send(ticket_access)
    when KnowledgeBase::AnswerPolicy
      policy.show?
    end
  end

  def object_policy(object_name, id: nil, number: nil)
    case [object_name, id, number]
    in ['Ticket', id, nil]
      ticket_policy(:id, id)
    in ['Ticket', nil, number]
      ticket_policy(:number, number)
    in ['KnowledgeBase::Answer::Translation', *_]
      kb_answer_policy(id.presence || number.presence)
    end
  end

  def kb_answer_policy(id)
    answer_id = KnowledgeBase::Answer::Translation.find(id).answer_id
    answer    = KnowledgeBase::Answer.find(answer_id)

    KnowledgeBase::AnswerPolicy.new(user, answer)
  end

  def ticket_policy(key, id)
    ticket = Ticket.find_by!(key => id)

    TicketPolicy.new(user, ticket)
  end
end
