# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
