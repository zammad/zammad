class Sequencer
  class Unit
    module Import
      module Ldap
        module Users
          class DryRun
            class Flag < Sequencer::Unit::Base
              uses :import_job
              provides :dry_run

              def process
                state.provide(:dry_run, import_job.dry_run)
              end
            end
          end
        end
      end
    end
  end
end
