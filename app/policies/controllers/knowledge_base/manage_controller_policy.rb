class Controllers::KnowledgeBase::ManageControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  default_permit!('admin.knowledge_base')
end
