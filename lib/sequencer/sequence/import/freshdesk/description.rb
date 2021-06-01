# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Freshdesk
        class Description < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Ticket::Article',
              'Import::Freshdesk::Description::Mapping',
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
      end
    end
  end
end
