# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Freshdesk::TimeEntry::Skip < Sequencer::Unit::Base
  uses :time_entry_available
  provides :action

  def process
    return if time_entry_available

    state.provide(:action, :skipped)
  end
end
