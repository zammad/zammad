class Sequencer
  class Unit
    module Import
      module Ldap
        module Users
          class StaticAttributes < Sequencer::Unit::Base

            provides :model_class

            def process
              state.provide(:model_class, ::User)
            end
          end
        end
      end
    end
  end
end
