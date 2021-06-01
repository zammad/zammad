# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          class Create < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure
            prepend ::Sequencer::Unit::Import::Common::Model::Mixin::Skip::Action

            skip_any_action

            uses :mapped, :model_class
            provides :instance, :action

            def process
              instance = model_class.new(mapped)
              state.provide(:instance, instance)
              state.provide(:action, :created)
            rescue => e
              handle_failure(e)
            end
          end
        end
      end
    end
  end
end
