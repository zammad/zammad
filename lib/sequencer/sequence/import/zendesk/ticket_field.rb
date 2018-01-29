class Sequencer
  class Sequence
    module Import
      module Zendesk
        class TicketField < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Ticket',
              'Import::Zendesk::TicketField::CheckCustom',
              'Import::Zendesk::TicketField::SanitizedName',
              'Import::Zendesk::TicketField::Add',
            ]
          end
        end
      end
    end
  end
end
