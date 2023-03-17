# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Zendesk::Ticket < Sequencer::Sequence::Base

  def self.sequence
    [
      'Import::Zendesk::Ticket::Skip::Deleted',
      'Import::Zendesk::Ticket::UserId',
      'Import::Zendesk::Ticket::OwnerId',
      'Import::Zendesk::Ticket::GroupId',
      'Import::Zendesk::Ticket::OrganizationId',
      'Import::Zendesk::Ticket::PriorityId',
      'Import::Zendesk::Ticket::StateId',
      'Import::Zendesk::Common::ArticleSenderId',
      'Import::Zendesk::Common::ArticleTypeId',
      'Import::Zendesk::Ticket::Subject',
      'Import::Zendesk::Ticket::CustomFields',
      'Import::Zendesk::Ticket::Mapping',
      'Common::ModelClass::Ticket',
      'Import::Common::Model::FindBy::Id',
      'Import::Common::Model::Update',
      'Import::Common::Model::Create',
      'Import::Common::Model::Save',
      'Import::Common::Model::ResetPrimaryKeySequence',
      'Import::Zendesk::Ticket::Tags',
      'Import::Zendesk::Ticket::Comments',
      'Import::Common::Model::Statistics::Diff::ModelKey',
      'Import::Common::ImportJob::Statistics::Update',
      'Import::Common::ImportJob::Statistics::Store',
    ]
  end
end
