# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Freshdesk
        class TimeEntry < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Ticket::TimeAccounting',
              'Import::Freshdesk::TimeEntry::Mapping',
              'Import::Common::Model::Update',
              'Import::Common::Model::Create',
              'Import::Common::Model::Save',
            ]
          end
        end
      end
    end
  end
end
