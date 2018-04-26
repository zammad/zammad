require_dependency 'sequencer/unit/import/common/model/mixin/handle_failure'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          class Save < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

            uses :instance, :dry_run
            provides :instance

            def process
              return if dry_run
              return if instance.blank?
              instance.save!
            rescue => e
              handle_failure(e)

              # unset instance if something went wrong
              state.provide(:instance, nil)
            end
          end
        end
      end
    end
  end
end
