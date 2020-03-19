class Controllers::KnowledgeBase::CategoriesControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  def show?
    return if user.permissions?('knowledge_base.editor')

    record.klass.find(params[:id]).internal_content?
  end
end
