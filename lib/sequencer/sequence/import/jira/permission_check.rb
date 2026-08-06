# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Jira::PermissionCheck < Sequencer::Sequence::Base

  def self.expecting
    [:permission_present]
  end

  def self.sequence
    [
      'Jira::PermissionPresent',
    ]
  end
end
