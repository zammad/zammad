require_dependency 'sequencer/unit/common/mixin/dynamic_attribute'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Skip
            module Blank
              class Base < Sequencer::Unit::Base
                include ::Sequencer::Unit::Common::Mixin::DynamicAttribute
                prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

                skip_any_action

                provides :action

                def process
                  return if !skip?

                  logger.debug { "Skipping. Blank #{attribute} found: #{attribute_value.inspect}" }
                  state.provide(:action, :skipped)
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
                  attribute_value.except(*ignore).values.none?(&:present?)
                end
              end
            end
          end
        end
      end
    end
  end
end
