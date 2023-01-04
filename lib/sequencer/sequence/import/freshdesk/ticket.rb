# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::Ticket < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::Ticket',
      # Fetch additional data such as attachments which is not included
      #   in the ticket list endpoint.
      'Import::Freshdesk::Ticket::Fetch',
      'Import::Freshdesk::Ticket::Mapping',
      'Import::Freshdesk::Mapping::CustomFields',
      'Import::Common::Model::FindBy::Number',
      'Import::Common::Model::Attributes::AddByIds',
      'Import::Common::Model::Update',
      'Import::Common::Model::Create',
      'Import::Common::Model::Save',
      'Import::Freshdesk::MapId',
      'Import::Freshdesk::Ticket::Tags',
      'Import::Freshdesk::Ticket::TimeEntries',
      'Import::Freshdesk::Ticket::Description',
      'Import::Freshdesk::Ticket::Conversations',
      'Import::Common::Model::Statistics::Diff::ModelKey',
      'Import::Common::ImportJob::Statistics::Update',
      'Import::Common::ImportJob::Statistics::Store',
    ]
  end
end
