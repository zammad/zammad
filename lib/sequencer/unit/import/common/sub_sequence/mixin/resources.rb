# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module SubSequence
          module Mixin
            module Resources
              include ::Sequencer::Unit::Import::Common::SubSequence::Mixin::Base

              def process
                return if resources.blank?

                sequence_resources(resources)
              end

              private

              def resources
                raise "Missing implementation of '#{__method__}' method for '#{self.class.name}'"
              end
            end
          end
        end
      end
    end
  end
end
