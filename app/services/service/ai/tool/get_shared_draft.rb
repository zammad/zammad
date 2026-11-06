# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads a ticket's shared draft in full, as the interface shows it to an agent who may change the ticket: its facts,
#   which get_ticket names as well, and its text, marked as an agent's (Service::AI::Tool::Output::SharedDraft).
class Service::AI::Tool::GetSharedDraft < Service::AI::Tool
  Draft = Service::AI::Tool::Output::SharedDraft

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      ticket:       Service::AI::Tool::Output::TicketReference::SCHEMA,
      shared_draft: Draft::SCHEMA.deep_merge(
        properties: { text: { type: 'string', description: 'The draft\'s text, as plain text, without the signature Zammad adds when it is sent.' } },
        required:   [*Draft::SCHEMA[:required], 'text'],
      ),
    },
    required:   %w[ticket shared_draft],
  }.freeze

  description 'Read the shared draft of a ticket in full: the reply an agent saved in Zammad to send later, with its ' \
              'type, recipients, subject, who saved it and its text. get_ticket names whether a ticket has one. ' \
              'send_shared_draft sends it as it is; save_shared_draft replaces it.'
  title 'Get shared draft'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents

  # The interface shows a draft to whoever may change the ticket, as its policy decides.
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true

  def execute
    draft = Service::AI::Tool::Lookup::SharedDraft.of(ticket, user: current_user)
    return none if draft.nil?

    summary = Draft.summary(draft)
    text    = Draft.readable_text(draft)
    content = { ticket: Service::AI::Tool::Output::TicketReference.of(ticket), shared_draft: summary.content.merge(text:) }

    Service::AI::Tool::Runtime::Result.ok(content, text: [summary.text, Draft.marked_text(text)].join("\n\n"))
  end

  private

  def none
    # Written for the model, like every text a tool returns, so not translated.
    Service::AI::Tool::Runtime::Result.error('not_found', "Ticket #{ticket.number} has no shared draft.")
  end
end
