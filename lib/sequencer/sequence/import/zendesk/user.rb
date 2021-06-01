# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Zendesk
        class User < Sequencer::Sequence::Base

          def self.sequence
            [
              'Import::Zendesk::User::Initiator',
              'Import::Zendesk::User::Roles',
              'Import::Zendesk::User::Groups',
              'Import::Zendesk::User::Login',
              'Import::Zendesk::User::Password',
              'Import::Zendesk::User::ImageSource',
              'Import::Zendesk::User::OrganizationID',
              'Common::ModelClass::User',
              'Import::Zendesk::User::Mapping',
              'Import::Zendesk::User::CustomFields',
              'Import::Common::Model::Attributes::AddByIds',
              'Import::Common::Model::FindBy::UserAttributes',
              'Import::Common::Model::Update',
              'Import::Common::Model::Create',
              'Import::Common::Model::Save',
              'Import::Common::Model::Statistics::Diff::ModelKey',
              'Import::Common::ImportJob::Statistics::Update',
              'Import::Common::ImportJob::Statistics::Store',
            ]
          end
        end
      end
    end
  end
end
