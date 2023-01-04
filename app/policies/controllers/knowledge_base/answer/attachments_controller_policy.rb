# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::Answer::AttachmentsControllerPolicy < Controllers::ApplicationControllerPolicy
  permit! :clone_to_form, to: 'knowledge_base.*'
  default_permit!('knowledge_base.editor')
end
