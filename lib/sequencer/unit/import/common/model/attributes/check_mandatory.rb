class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Attributes
            class CheckMandatory < Sequencer::Unit::Base
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

              skip_any_action

              uses :mapped
              provides :action

              def process
                mandatory.each do |mapped_attribute|
                  next if mapped[mapped_attribute].present?

                  logger.info { "Skipping. Missing mandatory attribute '#{mapped_attribute}'." }
                  state.provide(:action, :skipped)
                  break
                end
              end

              private

              def mandatory
                raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
              end
            end
          end
        end
      end
    end
  end
end
