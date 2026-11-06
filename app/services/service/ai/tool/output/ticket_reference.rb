# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A ticket a write tool names in its result: its ID, its number and its link, so that a client can open it.
module Service::AI::Tool::Output::TicketReference
  # Written for the model, like every text a tool returns, so not translated.
  SCHEMA = {
    type:       'object',
    properties: {
      id:     { type: 'integer' },
      number: { type: 'string' },
      url:    { type: 'string', description: 'A link to the ticket in Zammad.' }, # rubocop:disable Zammad/DetectTranslatableString
    },
    required:   %w[id number url],
  }.freeze

  def self.of(ticket)
    { id: ticket.id, number: ticket.number, url: Service::AI::Tool::ObjectLink.url(type: 'Ticket', id: ticket.id) }
  end
end
