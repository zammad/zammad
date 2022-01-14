# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Statistics
            module Diff
              class TopLevel < Sequencer::Unit::Base
                include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff

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
end
