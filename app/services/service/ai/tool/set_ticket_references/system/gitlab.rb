# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::SetTicketReferences::System::GitLab < Service::AI::Tool::SetTicketReferences::System::IssueTracker
  # rubocop:disable-next Zammad/DetectTranslatableString
  references 'gitlab', label: 'GitLab', noun: 'GitLab issue', setting: 'gitlab_integration'
end
