# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::LinksControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.tag')

  def add?
    object_target_update? && object_source_show?
  end

  def remove?
    object_target_update?
  end

  private

  def object_target_update?
    object_policy(record.params[:link_object_target], id: record.params[:link_object_target_value])
      .update?
  end

  def object_source_show?
    object_policy(record.params[:link_object_source], number: record.params[:link_object_source_number])
      .show?
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
