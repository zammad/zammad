class Sequencer
  class Unit
    module Import
      module Common
        module Model
          module Mixin
            module Skip
              module InstanceAction

                module ClassMethods

                  def skip_instance_action(*instance_actions)
                    declaration_accessor(
                      key:        __method__,
                      attributes: instance_actions
                    )
                  end
                  alias skip_instance_actions skip_instance_action

                  def skip_any_instance_action
                    skip_instance_actions(:any)
                  end

                  def skip_instance_action?(instance_action)
                    logger.debug("Checking if skip is necessary for instance_action #{instance_action.inspect}.")
                    return false if instance_action.blank?
                    logger.debug("Checking if skip is necessary for skip_instance_actions #{skip_instance_actions.inspect}.")
                    return false if skip_instance_actions.blank?
                    return true if skip_instance_actions.include?(instance_action)
                    return true if skip_instance_actions.include?(:any)
                    false
                  end
                end

                def self.prepended(base)
                  base.extend(ClassMethods)
                end

                def process
                  instance_action = state.optional(:instance_action)
                  if self.class.skip_instance_action?(instance_action)
                    logger.debug("Skipping due to provided instance_action #{instance_action.inspect}.")
                  else
                    logger.debug("Nope. Won't skip instance_action #{instance_action.inspect}.")
                    super
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
