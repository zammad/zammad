# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Jira::Full < Sequencer::Sequence::Base

  def self.sequence
    [
      'Import::Common::ImportMode::Check',
      'Import::Common::SystemInitDone::Check',
      'Import::Common::ImportJob::DryRun',
      'Import::Jira::Issues',
      'Import::Common::SystemInitDone::Set',
      'Import::Common::ImportMode::Unset',
    ]
  end
end
