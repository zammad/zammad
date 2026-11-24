# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::SetTicketReferences::System::GitHub < Service::AI::Tool::SetTicketReferences::System::IssueTracker
  # rubocop:disable-next Zammad/DetectTranslatableString
  references 'github', label: 'GitHub', noun: 'GitHub issue', setting: 'github_integration'
end
