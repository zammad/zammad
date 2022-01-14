# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
