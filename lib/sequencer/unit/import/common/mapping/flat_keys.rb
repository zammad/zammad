# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Mapping
          class FlatKeys < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Mapping::Mixin::ProvideMapped
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            skip_any_action

            uses :resource
            provides :mapped

            def process
              provide_mapped do
                mapped
              end
            end

            private

            def mapped
              @mapped ||= begin
                resource_with_indifferent_access = resource.with_indifferent_access
                mapping.symbolize_keys.collect do |source, local|
                  [local, resource_with_indifferent_access[source]]
                end.to_h.with_indifferent_access
              end
            end

            def mapping
              raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
            end
          end
        end
      end
    end
  end
end
