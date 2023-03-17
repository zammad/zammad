# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Sequencer::Unit::Import::Common::SubSequence::Mixin::ImportJob
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
