# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TagsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.tag')

  def search?
    user.permissions?(['ticket.agent', 'admin.tag', 'knowledge_base.editor'])
  end

  def list?
    object_read?
  end

  def add?
    object_update?
  end

  def remove?
    object_update?
  end

  private

  def object_read?
    object_policy.show?
  end

  def object_update?
    object_policy.agent_update_access?
  end

  def klass
    case record.params[:object]
    when 'Ticket'
      Ticket
    when %r{KnowledgeBase::Answer(?:::.+)?}
      KnowledgeBase::Answer
    end
  end

  def object_policy
    object = klass.find record.params[:o_id]
    policy = Pundit::PolicyFinder.new(object).policy!

    policy.new user, object
  end
end
