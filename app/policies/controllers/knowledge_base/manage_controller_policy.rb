# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::ManageControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  default_permit!('admin.knowledge_base')
end
