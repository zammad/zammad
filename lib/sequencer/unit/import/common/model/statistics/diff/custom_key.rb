# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'sequencer/unit/import/common/model/statistics/mixin/action_diff'
class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Statistics
            module Diff
              class CustomKey < Sequencer::Unit::Base
                include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff

                def process
                  state.provide(:statistics_diff) do
                    {
                      key => diff,
                    }
                  end
                end

                private

                def key
                  raise "Missing implementation of method 'key' for class #{self.class.name}"
                end
              end
            end
          end
        end
      end
    end
  end
end
