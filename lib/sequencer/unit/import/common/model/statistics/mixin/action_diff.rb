# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
