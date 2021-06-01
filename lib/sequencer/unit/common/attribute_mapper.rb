# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Common
      class AttributeMapper < Sequencer::Unit::Base

        def self.map
          raise "Missing implementation of '#{__method__}' method for '#{name}'"
        end

        def self.uses
          map.keys
        end

        def self.provides
          map.values
        end

        def process
          self.class.map.each do |original, renamed|
            state.provide(renamed) do
              state.use(original)
            end
          end
        end
      end
    end
  end
end
