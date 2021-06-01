# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Ldap
        class User < Sequencer::Sequence::Base

          def self.expecting
            [:instance]
          end

          def self.sequence
            [
              'Import::Ldap::User::NormalizeEntry',
              'Import::Ldap::User::RemoteId::FromEntry',
              'Import::Ldap::User::RemoteId::Unhex',
              'Import::Ldap::User::Mapping',
              'Import::Ldap::User::Skip::MissingMandatory',
              'Import::Ldap::User::Skip::Blank',
              'Import::Common::Model::Lookup::ExternalSync',
              'Import::Common::User::Attributes::Downcase',
              'Import::Common::User::Email::CheckValidity',
              'Import::Ldap::User::Lookup::Attributes',
              'Import::Ldap::User::Attributes::RoleIds::Dn',
              'Import::Ldap::User::Attributes::RoleIds::Unassigned',
              'Import::Ldap::User::Attributes::RoleIds::Signup',
              'Import::Common::Model::Associations::Extract',
              'Import::Ldap::User::Attributes::Static',
              'Import::Common::Model::Attributes::AddByIds',
              'Import::Common::Model::Update',
              'Import::Common::Model::Create',
              'Import::Common::Model::Associations::Assign',
              'Import::Common::Model::Save',
              'Import::Common::Model::ExternalSync::Integrity',
              'Import::Ldap::User::HttpLog',
              'Import::Ldap::User::Statistics::Diff',
              'Import::Common::ImportJob::Statistics::Update',
              'Import::Common::ImportJob::Statistics::Store',
            ]
          end
        end
      end
    end
  end
end
