# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Statistics
            class Total < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Statistics::Mixin::EmptyDiff

              def process
                state.provide(:statistics_diff) do
                  diff.merge(
                    total: total
                  )
                end
              end

              private

              def total
                raise "Missing implementation if total method for class #{self.class.name}"
              end
            end
          end
        end
      end
    end
  end
end
