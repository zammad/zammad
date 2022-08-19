# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TagsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.tag')

  def add?
    object_update?
  end

  def remove?
    object_update?
  end

  private

  def object_update?
    case record.params[:object]
    when 'Ticket'
      return ticket_update?
    when %r{KnowledgeBase::Answer(?:::.+)?}
      return kb_answer_update?
    end

    true
  end

  def ticket_update?
    ticket = Ticket.find(record.params[:o_id])
    TicketPolicy.new(user, ticket).update?
  end

  def kb_answer_update?
    answer = KnowledgeBase::Answer.find(record.params[:o_id])
    KnowledgeBase::AnswerPolicy.new(user, answer).update?
  end
end
