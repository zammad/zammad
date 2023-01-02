# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Ldap::Sources < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::User',
      'Ldap::ExternalSyncSource',
      'Import::Common::ImportJob::DryRun',
      'Import::Ldap::Sources::DryRun::Payload',
      'Import::Ldap::Sources::Configs',
      'Import::Ldap::Sources::SubSequence',
      'Import::Ldap::Sources::Lost::Ids',
      'Import::Ldap::Sources::Lost::StatisticsDiff',
      'Import::Ldap::Sources::Lost::Deactivate',
    ]
  end
end
