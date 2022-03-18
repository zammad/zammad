# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
