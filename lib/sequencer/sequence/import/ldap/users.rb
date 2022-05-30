# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Ldap
        class Users < Sequencer::Sequence::Base
          def self.expecting
            [:found_ids]
          end

          def self.sequence
            [
              'Common::ModelClass::User',
              'Ldap::ExternalSyncSource',
              'Ldap::Config',
              'Ldap::Connection',
              'Import::Ldap::Users::UserRoles',
              'Import::Ldap::Users::Total',
              'Import::Common::ImportJob::Statistics::Update',
              'Import::Common::ImportJob::Statistics::Store',
              'Import::Ldap::Users::SubSequence',
            ]
          end
        end
      end
    end
  end
end
