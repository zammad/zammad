# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Exchange::FolderContact < Sequencer::Sequence::Base

  def self.sequence
    [
      'Import::Exchange::FolderContact::RemoteId',
      'Import::Common::RemoteId::CaseSensitive',
      'Import::Exchange::FolderContact::Mapping::FromConfig',
      'Import::Exchange::FolderContact::Mapping::Login',
      'Common::ModelClass::User',
      'Import::Common::Model::Skip::Blank::Mapped',
      'Import::Exchange::FolderContact::ExternalSyncSource',
      'Import::Common::Model::Lookup::ExternalSync',
      'Import::Common::Model::Associations::Extract',
      'Import::Common::User::Attributes::Downcase',
      'Import::Common::User::Email::CheckValidity',
      'Import::Common::Model::FindBy::UserAttributes',
      'Import::Common::User::Skip::IsLdapSource',
      'Import::Common::Model::Attributes::AddByIds',
      'Import::Common::Model::Update',
      'Import::Common::Model::Create',
      'Import::Common::Model::Associations::Assign',
      'Import::Common::Model::Save',
      'Import::Common::Model::ExternalSync::Integrity',
      'Import::Exchange::FolderContact::HttpLog',
      'Import::Exchange::FolderContact::Statistics::Diff',
      'Import::Common::ImportJob::Statistics::Update',
      'Import::Common::ImportJob::Statistics::Store',
    ]
  end
end
