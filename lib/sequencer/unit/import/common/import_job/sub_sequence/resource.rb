class Sequencer
  class Unit
    module Import
      module Common
        module ImportJob
          module SubSequence
            class Resource < Sequencer::Unit::Import::Common::ImportJob::SubSequence::General
              uses :resource
            end
          end
        end
      end
    end
  end
end
