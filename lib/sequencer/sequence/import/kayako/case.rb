# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Kayako::Case < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::Ticket',
      'Import::Kayako::Case::Skip::Deleted',
      'Import::Kayako::Case::Skip::Suspended',
      'Import::Kayako::Common::CreatedById',
      'Import::Kayako::Common::ArticleSenderId',
      'Import::Kayako::Case::UpdatedById',
      'Import::Kayako::Case::CustomerId',
      'Import::Kayako::Case::OwnerId',
      'Import::Kayako::Case::GroupId',
      'Import::Kayako::Case::OrganizationId',
      'Import::Kayako::Case::PriorityId',
      'Import::Kayako::Case::StateId',
      'Import::Kayako::Case::Type',
      'Import::Kayako::Common::ArticleSourceChannel',
      'Import::Kayako::Case::Mapping',
      'Import::Kayako::Mapping::Timestamps',
      'Import::Kayako::Mapping::CustomFields',
      'Import::Common::Model::FindBy::Id',
      'Import::Common::Model::Update',
      'Import::Common::Model::Create',
      'Import::Common::Model::Save',
      'Import::Common::Model::ResetPrimaryKeySequence',
      'Import::Kayako::MapId',
      'Import::Kayako::Case::Tags',
      'Import::Kayako::Case::Posts',
      'Import::Common::Model::Statistics::Diff::ModelKey',
      'Import::Common::ImportJob::Statistics::Update',
      'Import::Common::ImportJob::Statistics::Store',
    ]
  end
end
