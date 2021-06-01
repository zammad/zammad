# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Sequencer
  class Unit
    module Import
      module Common
        module SubSequence
          module Mixin
            module ImportJob
              include ::Sequencer::Unit::Import::Common::SubSequence::Mixin::Base

              def self.included(base)
                base.uses :import_job
              end

              private

              def default_params
                {
                  dry_run:    import_job.dry_run,
                  import_job: import_job,
                }
              end
            end
          end
        end
      end
    end
  end
end
