# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::KnowledgeBase::ManageControllerPolicy < Controllers::KnowledgeBase::BaseControllerPolicy
  default_permit!('admin.knowledge_base')
end
