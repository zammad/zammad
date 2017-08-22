require 'sequencer/unit/mixin/dynamic_attribute'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Skip
            module Blank
              class Base < Sequencer::Unit::Base
                prepend ::Sequencer::Unit::Import::Common::Model::Mixin::SkipOnProvidedInstanceAction
                include ::Sequencer::Unit::Mixin::DynamicAttribute

                provides :instance_action

                def process
                  return if !skip?
                  logger.debug("Skipping. Blank #{attribute} found: #{attribute_value.inspect}")
                  state.provide(:instance_action, :skipped)
                end

                private

                def ignore
                  [:id]
                end

                def skip?
                  return true if attribute_value.blank?
                  relevant_blank?
                end

                def relevant_blank?
                  !attribute_value.except(*ignore).values.any?(&:present?)
                end
              end
            end
          end
        end
      end
    end
  end
end
