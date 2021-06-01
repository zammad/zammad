# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Lookup
            class Attributes < Sequencer::Unit::Base
              include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
              prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

              skip_action :skipped, :failed

              uses :mapped, :model_class
              provides :instance

              def process
                return if state.provided?(:instance)
                return if existing_instance.blank?

                state.provide(:instance, existing_instance)
              end

              private

              def attribute
                raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
              end

              def attributes
                # alias or alias_method won't work if attribute method
                # is overwritten in inheriting sub-class
                attribute
              end

              def existing_instance
                @existing_instance ||= begin
                  Array(attributes).find do |attribute|

                    value = mapped[attribute]
                    next if value.blank?

                    existing_instance = lookup(
                      attribute: attribute,
                      value:     value
                    )

                    next if existing_instance.blank?

                    # https://stackoverflow.com/a/24901650/7900866
                    break existing_instance
                  end
                end
              end

              def lookup(attribute:, value:)
                return model_class.identify(value) if model_class.respond_to?(:identify)

                model_class.find_by(attribute => value)
              end
            end
          end
        end
      end
    end
  end
end
