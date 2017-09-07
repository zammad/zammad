require 'sequencer/unit/import/common/model/mixin/handle_failure'

class Sequencer
  class Unit
    module Import
      module Common
        module Model
          class Save < Sequencer::Unit::Base
            include ::Sequencer::Unit::Import::Common::Model::Mixin::HandleFailure

            uses :instance, :dry_run

            def process
              return if dry_run
              return if instance.blank?
              instance.save!
            rescue => e
              handle_failure(e)
            end
          end
        end
      end
    end
  end
end
