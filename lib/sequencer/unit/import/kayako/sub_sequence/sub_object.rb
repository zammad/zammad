# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Kayako
        module SubSequence
          class SubObject < Sequencer::Unit::Import::Kayako::SubSequence::Generic

            uses :instance

            def sequence_params
              super.merge(
                instance: instance,
              )
            end
          end
        end
      end
    end
  end
end
