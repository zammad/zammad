# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Zendesk
        class TicketField < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Ticket',
              'Import::Zendesk::TicketField::CheckCustom',
              'Import::Zendesk::ObjectAttribute::SanitizedType',
              'Import::Zendesk::TicketField::SanitizedName',
              'Import::Zendesk::ObjectAttribute::Add',
            ]
          end
        end
      end
    end
  end
end
