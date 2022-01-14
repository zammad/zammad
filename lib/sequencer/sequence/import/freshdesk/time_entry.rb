# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Freshdesk
        class TimeEntry < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Ticket::TimeAccounting',
              'Import::Freshdesk::TimeEntry::Mapping',
              'Import::Common::Model::FindBy::TimeAccountingAttributes',
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
