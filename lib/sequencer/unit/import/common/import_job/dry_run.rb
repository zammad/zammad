class Sequencer
  class Unit
    module Import
      module Common
        module ImportJob
          class DryRun < Sequencer::Unit::Common::Provider::Named

            uses :import_job

            delegate dry_run: :import_job
          end
        end
      end
    end
  end
end
