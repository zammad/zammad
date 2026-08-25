# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Shared write plumbing of the knowledge base category create and update services.
class Service::KnowledgeBase::Category::Base < Service::KnowledgeBase::Base
  include Service::KnowledgeBase::Concerns::AppliesPermissions
  include Service::KnowledgeBase::Category::Concerns::AssignsTitle

  # Both services authorize through KnowledgeBase::CategoryPolicy, which needs a user.
  requires_current_user!
end
