# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Common::ImportJob::DryRun < Sequencer::Unit::Common::Provider::Named

  uses :import_job

  delegate dry_run: :import_job
end
