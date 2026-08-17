# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::AnswersControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def show?
    access(__method__)
  end

  def create?
    verify_category(:update?)
  end

  def update?
    access(__method__) && verify_category(__method__)
  end

  def destroy?
    access(__method__)
  end

  # The `has_publishing` route concern generates one action per state machine event. Deriving
  #   the gates the same way keeps a newly added event from inheriting the base policy's
  #   `knowledge_base.*` default, which any `knowledge_base.reader` satisfies.
  def has_publishing_update? # rubocop:disable Naming/PredicatePrefix
    access(:update?)
  end

  CanBePublished::StateMachine.aasm.events.each do |event|
    define_method(:"has_publishing_#{event.name}?") { access(:update?) }
  end

  private

  def object
    @object ||= record.klass.find(record.params[:id])
  end

  def access(method)
    KnowledgeBase::AnswerPolicy.new(user, object).send(method)
  end

  def verify_category(method)
    new_category = KnowledgeBase::Category.find(record.params[:category_id])

    KnowledgeBase::CategoryPolicy.new(user, new_category).send(method)
  end
end
