# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Freshdesk
        class Conversation < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Ticket::Article',
              'Import::Freshdesk::Conversation::Mapping',
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
