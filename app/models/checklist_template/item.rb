# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class ChecklistTemplate::Item < ApplicationModel
  include ChecksClientNotification
  include HasDefaultModelUserRelations

  belongs_to :checklist_template
end
