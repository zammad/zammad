# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Zendesk::User < Sequencer::Sequence::Base

  def self.sequence
    [
      'Import::Zendesk::User::Initiator',
      'Import::Zendesk::User::Roles',
      'Import::Zendesk::User::Groups',
      'Import::Zendesk::User::Login',
      'Import::Zendesk::User::Password',
      'Import::Zendesk::User::ImageSource',
      'Import::Zendesk::User::OrganizationId',
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
