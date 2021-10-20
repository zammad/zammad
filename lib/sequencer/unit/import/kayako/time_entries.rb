# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        class TimeEntries < Sequencer::Unit::Import::Kayako::SubSequence::Object
          def sequence_name
            'Sequencer::Sequence::Import::Kayako::TimeEntries'.freeze
          end
        end
      end
    end
  end
end
