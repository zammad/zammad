# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Ldap
        class Users < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::User',
              'Import::Ldap::Users::ExternalSyncSource',
              'Import::Common::ImportJob::DryRun',
              'Import::Ldap::Users::DryRun::Payload',
              'Ldap::Config',
              'Ldap::Connection',
              'Import::Ldap::Users::UserRoles',
              'Import::Ldap::Users::Total',
              'Import::Common::ImportJob::Statistics::Update',
              'Import::Common::ImportJob::Statistics::Store',
              'Import::Ldap::Users::SubSequence',
              'Import::Ldap::Users::Lost::Ids',
              'Import::Ldap::Users::Lost::StatisticsDiff',
              'Import::Ldap::Users::Lost::Deactivate',
            ]
          end
        end
      end
    end
  end
end
