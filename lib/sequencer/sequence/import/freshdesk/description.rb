# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Sequence::Import::Freshdesk::Description < Sequencer::Sequence::Base

  def self.sequence
    [
      'Common::ModelClass::Ticket::Article',
      'Import::Freshdesk::Description::Mapping',
      'Import::Common::Model::FindBy::MessageId',
      # Handling of inline images and attachments is the same for first article (description)
      #   and subsequent articles (conversation).
      'Import::Freshdesk::Conversation::InlineImages',
      'Import::Common::Model::Update',
      'Import::Common::Model::Create',
      'Import::Common::Model::Save',
      'Import::Freshdesk::MapId',
      'Import::Freshdesk::Conversation::Attachments',
    ]
  end
end
