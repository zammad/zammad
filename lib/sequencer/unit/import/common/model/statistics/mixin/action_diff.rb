# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require_dependency 'sequencer/unit/import/common/model/statistics/mixin/common'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Statistics
            module Mixin
              module ActionDiff
                include Sequencer::Unit::Import::Common::Model::Statistics::Mixin::Common

                def self.included(base)
                  base.uses :action
                  base.provides :statistics_diff
                end

                private

                def diff
                  raise "Unknown action '#{action}'" if !possible?

                  empty_diff.merge(
                    action => 1,
                    sum: 1,
                  )
                end

                def possible?
                  possible_actions.include?(action)
                end
              end
            end
          end
        end
      end
    end
  end
end
