# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::Conversation < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::Ticket::Article',
      'Import::Freshdesk::Conversation::Mapping',
      'Import::Freshdesk::Conversation::InlineImages',
      'Import::Common::Model::FindBy::MessageId',
      'Import::Common::Model::Update',
      'Import::Common::Model::Create',
      'Import::Common::Model::Save',
      'Import::Freshdesk::MapId',
      'Import::Freshdesk::Conversation::Attachments',
    ]
  end
end
