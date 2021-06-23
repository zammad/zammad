# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Statistics
            module Mixin
              module Common
                private

                def actions
                  %i[skipped created updated unchanged failed deactivated]
                end

                def results
                  %i[sum total]
                end

                def empty_diff
                  possible_actions.index_with { |_key| 0 }
                end

                def possible_actions
                  @possible_actions ||= actions + results
                end
              end
            end
          end
        end
      end
    end
  end
end
