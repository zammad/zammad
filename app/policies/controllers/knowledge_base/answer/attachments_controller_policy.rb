# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::KnowledgeBase::Answer::AttachmentsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :clone_to_form, to: 'knowledge_base.*'
  default_permit!('knowledge_base.editor')
end
