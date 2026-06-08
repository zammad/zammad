# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::Ticket::KnowledgeBaseAnswersControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('ticket.agent+knowledge_base.editor')
end
