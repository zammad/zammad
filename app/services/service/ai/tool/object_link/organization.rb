# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Tool::ObjectLink::Organization < Service::AI::Tool::ObjectLink
  page 'Organization', 'organization/profile/%{id}'
end
