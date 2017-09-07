require 'sequencer/unit/import/common/model/statistics/mixin/diff'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Statistics
            class Diff < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::Diff

              def process
                state.provide(:statistics_diff, diff)
              end
            end
          end
        end
      end
    end
  end
end
