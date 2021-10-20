# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module SubSequence
          class Object < Sequencer::Unit::Import::Kayako::SubSequence::Generic

            def sequence_name
              'Sequencer::Sequence::Import::Kayako::GenericObject'.freeze
            end
          end
        end
      end
    end
  end
end
