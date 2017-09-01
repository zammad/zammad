require 'sequencer/unit/import/common/model/statistics/mixin/common'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Statistics
            module Mixin
              module InstanceActionDiff
                include Sequencer::Unit::Import::Common::Model::Statistics::Mixin::Common

                def self.included(base)
                  base.uses :instance_action
                  base.provides :statistics_diff
                end

                private

                def diff
                  raise "Unknown action '#{instance_action}'" if !possible?
                  empty_diff.merge(
                    instance_action => 1,
                    sum: 1,
                  )
                end

                def possible?
                  possible_actions.include?(instance_action)
                end
              end
            end
          end
        end
      end
    end
  end
end
