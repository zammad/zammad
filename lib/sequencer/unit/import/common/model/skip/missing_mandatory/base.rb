require 'sequencer/unit/mixin/dynamic_attribute'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Skip
            module MissingMandatory
              class Base < Sequencer::Unit::Base
                prepend ::Sequencer::Unit::Import::Common::Model::Mixin::SkipOnProvidedInstanceAction
                include ::Sequencer::Unit::Mixin::DynamicAttribute

                provides :instance_action

                def process
                  return if !skip?
                  logger.debug("Skipping. Missing mandatory attributes for #{attribute}: #{attribute_value.inspect}")
                  state.provide(:instance_action, :skipped)
                end

                private

                def mandatory
                  raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
                end

                def skip?
                  return true if attribute_value.blank?
                  mandatory_missing?
                end

                def mandatory_missing?
                  values = attribute_value.fetch_values(*mandatory)
                  !values.any?(&:present?)
                rescue KeyError => e
                  false
                end
              end
            end
          end
        end
      end
    end
  end
end
