class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Statistics
            module Mixin
              module Diff

                def self.included(base)
                  base.uses :instance_action
                  base.provides :statistics_diff
                end

                private

                def actions
                  %i(skipped created updated unchanged failed deactivated)
                end

                def diff
                  raise "Unknown action '#{instance_action}'" if !possible?
                  defaults.merge(
                    instance_action => 1,
                    sum: 1,
                  )
                end

                def possible?
                  possible_actions.include?(instance_action)
                end

                def defaults
                  possible_actions.collect { |key| [key, 0] }.to_h
                end

                def possible_actions
                  @possible_actions ||= actions
                end
              end
            end
          end
        end
      end
    end
  end
end
