# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Kayako::TimeEntry::Skip < Sequencer::Unit::Base
  uses :resource
  provides :action

  def process
    return if resource['log_type'] != 'VIEWED'

    state.provide(:action, :skipped)
  end
end
