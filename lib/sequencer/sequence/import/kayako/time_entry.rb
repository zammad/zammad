# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Sequence
    module Import
      module Kayako
        class TimeEntry < Sequencer::Sequence::Base

          def self.sequence
            [
              'Common::ModelClass::Ticket::TimeAccounting',
              'Import::Kayako::TimeEntry::Skip',
              'Import::Kayako::Common::CreatedById',
              'Import::Kayako::TimeEntry::Mapping',
              'Import::Kayako::Mapping::Timestamps',
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
