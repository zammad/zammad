# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::LinksControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.tag')

  def add?
    object_update?
  end

  def remove?
    object_update?
  end

  private

  def object_update?
    return false if !object_target_update?
    return false if !object_source_show?

    true
  end

  def object_target_update?
    case record.params[:link_object_target]
    when 'Ticket'
      object_target_ticket_update?
    when %r{KnowledgeBase::Answer(?:::.+)?}
      object_target_kb_answer_update?
    end
  end

  def object_target_ticket_update?
    ticket = Ticket.find(record.params[:link_object_target_value])
    TicketPolicy.new(user, ticket).update?
  end

  def object_target_kb_answer_update?
    answer = KnowledgeBase::Answer.find(record.params[:link_object_target_value])
    KnowledgeBase::AnswerPolicy.new(user, answer).update?
  end

  def object_source_show?
    case record.params[:link_object_source]
    when 'Ticket'
      object_source_ticket_show?
    when %r{KnowledgeBase::Answer(?:::.+)?}
      object_source_kb_answer_show?
    end
  end

  def object_source_ticket_show?
    if record.params[:action] == 'add'
      ticket = Ticket.find_by(number: record.params[:link_object_source_number])
      return TicketPolicy.new(user, ticket).show?
    end

    true
  end

  def object_source_kb_answer_show?
    if record.params[:action] == 'add'
      answer = KnowledgeBase::Answer.find(record.params[:link_object_source_number])
      return KnowledgeBase::AnswerPolicy.new(user, answer).show?
    end

    true
  end
end
