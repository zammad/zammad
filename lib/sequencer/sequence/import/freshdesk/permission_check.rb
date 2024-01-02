# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::PermissionCheck < Sequencer::Sequence::Base

  def self.expecting
    [:permission_present]
  end

  def self.sequence
    [
      'Freshdesk::PermissionPresent',
    ]
  end
end
