# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'sequencer/unit/import/common/model/statistics/mixin/action_diff'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Statistics
            module Diff
              class ModelKey < Sequencer::Unit::Base
                include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::ActionDiff

                uses :model_class

                def process
                  state.provide(:statistics_diff) do
                    {
                      model_key => diff,
                    }
                  end
                end

                private

                def model_key
                  model_class.name.pluralize.to_sym
                end
              end
            end
          end
        end
      end
    end
  end
end
