# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
