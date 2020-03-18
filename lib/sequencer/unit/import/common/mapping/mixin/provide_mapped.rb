class Sequencer
  class Unit
    module Import
      module Common
        module Mapping
          module Mixin
            module ProvideMapped

              def self.included(base)
                base.optional :mapped
                base.provides :mapped
              end

              private

              def existing_mapped
                @existing_mapped ||= mapped || ActiveSupport::HashWithIndifferentAccess.new
              end

              def provide_mapped
                state.provide(:mapped) do
                  existing_mapped.merge(yield)
                end
              end
            end
          end
        end
      end
    end
  end
end
