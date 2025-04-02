# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::Conversation < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::Ticket::Article',
      'Import::Freshdesk::Conversation::User',
      'Import::Freshdesk::Conversation::Mapping',
      'Import::Common::Model::FindBy::MessageId',
      # It's important that the find by check is before the inline images mapping, because for the
      # update situation the old images needs to be deleted before the new ones are added.
      'Import::Freshdesk::Conversation::InlineImages',
      'Import::Common::Model::Update',
      'Import::Common::Model::Create',
      'Import::Common::Model::Save',
      'Import::Freshdesk::MapId',
      'Import::Freshdesk::Conversation::Attachments',
    ]
  end
end
