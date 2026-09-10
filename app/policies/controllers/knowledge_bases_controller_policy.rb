# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBasesControllerPolicy < Controllers::ApplicationControllerPolicy
  # The agent app's reads of the knowledge base itself. Each is named rather than covered by a
  #   wildcard `default_permit!`, so an action added to this controller arrives without a gate and
  #   has to be given one, instead of silently inheriting the most permissive one available.
  #
  # `knowledge_base.reader` satisfies these, which is the intent - what a reader may see of the
  #   content is decided per record by KnowledgeBase::CategoryPolicy and KnowledgeBase::
  #   AnswerPolicy, which #assets and #calculate_visible_ids resolve through
  #   KnowledgeBase.access_for_user. #preview is a read for the same reason: its token
  #   authenticates as the requesting user (KnowledgeBase::Public::BaseController
  #   #authenticate_with_preview_token), so it grants nobody more than they already have.
  permit! %i[show visible_ids preview], to: 'knowledge_base.*'

  def init?
    true
  end

  # There is only ever one knowledge base, and it is created and removed through
  #   KnowledgeBase::ManageController - which requires `admin.knowledge_base`. Neither action is
  #   routed here; both are denied outright so that routing one would not hand it a gate by
  #   accident.
  def create?
    false
  end

  def destroy?
    false
  end

  def update?
    access(__method__)
  end

  private

  def object
    @object ||= record.klass.find(record.params[:id])
  end

  def access(method)
    KnowledgeBase::CategoryPolicy.new(user, object).send(method)
  end
end
