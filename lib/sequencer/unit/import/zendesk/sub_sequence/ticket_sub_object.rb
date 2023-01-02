# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::SubSequence::TicketSubObject < Sequencer::Unit::Import::Zendesk::SubSequence::SubObject

  private

  def sequence_name
    "Import::Zendesk::Ticket::#{resource_klass}"
  end
end
