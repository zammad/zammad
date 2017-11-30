class Sequencer
  class Sequence
    module Import
      module Ldap
        class Users < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Ldap::Users::StaticAttributes',
              'Import::Ldap::Users::DryRun::Flag',
              'Import::Ldap::Users::DryRun::Payload',
              'Ldap::Config',
              'Ldap::Connection',
              'Import::Ldap::Users::UserRoles',
              'Import::Ldap::Users::Sum',
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
