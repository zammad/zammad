class Controllers::KnowledgeBase::Answer::AttachmentsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('knowledge_base.editor')
end
