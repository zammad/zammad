# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::AnswersControllerPolicy < Controllers::ApplicationControllerPolicy
  # The one action here that is not about a single answer, so it has no record to resolve access
  #   through: it hands out the ten most recently published answers, which is a read.
  #   KnowledgeBase::AnswersController#recent_answers scopes to `published`, so a reader sees only
  #   what a reader may see.
  permit! :recent_answers, to: 'knowledge_base.*'

  # The editorial lifecycle of one answer - the four state machine transitions, and the endpoint
  #   that writes their timestamps directly. Gated on the answer, at the same access
  #   KnowledgeBase::AnswerPolicy#update? asks for, which is what the desktop view requires of the
  #   same operation (`loads_pundit_method: :update?` on Gql::Mutations::KnowledgeBase::Answer::
  #   VisibilitySchedule::Add), so both stacks agree on who may publish.
  #
  # Derived from the same event list KnowledgeBase::AnswersController and the routes derive the
  #   actions from (HasPublishing, and the `:has_publishing` concern in
  #   config/routes/knowledge_base.rb), so a transition added there cannot arrive without a gate.
  #
  # Deliberately #access(:update?) rather than this policy's own #update?, which also runs
  #   #verify_category against `params[:category_id]` - a param these actions never carry, so it
  #   would fall back to checking the knowledge base and skip the answer's category. The same
  #   reasoning as the note on Controllers::KnowledgeBase::CategoriesControllerPolicy
  #   #reorder_categories?.
  [:update, *CanBePublished::StateMachine.aasm.events.map(&:name)].each do |event|
    define_method :"has_publishing_#{event}?" do
      access(:update?)
    end
  end

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
