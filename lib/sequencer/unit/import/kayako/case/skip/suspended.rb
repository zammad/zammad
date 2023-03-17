# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::Case::Skip::Suspended < Sequencer::Unit::Base

  uses :resource
  provides :action

  def process
    return if resource['state'] != 'SUSPENDED'

    logger.info { "Skipping. Kayako Case ID '#{resource['id']}' is in 'SUSPENDED' state." }
    state.provide(:action, :skipped)
  end
end
