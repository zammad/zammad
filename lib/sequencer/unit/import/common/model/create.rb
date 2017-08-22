class Sequencer
  class Unit
    module Import
      module Common
        module Model
          class Create < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::SkipOnProvidedInstanceAction

            uses :mapped, :model_class
            provides :instance, :instance_action

            def process
              instance = model_class.new(mapped)
              state.provide(:instance, instance)
              state.provide(:instance_action, :created)
            rescue => e
              handle_failure(e)
            end
          end
        end
      end
    end
  end
end
