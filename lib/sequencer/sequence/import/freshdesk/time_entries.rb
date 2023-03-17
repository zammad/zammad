# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::TimeEntries < Sequencer::Sequence::Base

  def self.sequence
    [
      'Import::Freshdesk::TimeEntry::Skip',
      'Import::Freshdesk::Request',
      'Import::Freshdesk::Resources',
      'Import::Freshdesk::ModelClass',
      'Import::Freshdesk::Perform',
    ]
  end
end
