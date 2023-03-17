# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Skip::Deleted < Sequencer::Unit::Base

  uses :resource
  provides :action

  def process
    return if resource.status != 'deleted'

    logger.info { "Skipping. Zendesk Ticket ID '#{resource.id}' is in 'deleted' state." }
    state.provide(:action, :skipped)
  end
end
