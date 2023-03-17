# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Sequencer::Unit::Import::Zendesk::Ticket::Comments < Sequencer::Unit::Import::Zendesk::SubSequence::TicketSubObject

  uses :user_map

  private

  def default_params
    super.merge(
      user_map: user_map,
    )
  end
end
