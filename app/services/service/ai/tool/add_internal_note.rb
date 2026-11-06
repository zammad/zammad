# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Adds an internal note to a ticket: an article as create_article writes one, with its type, its visibility and no
#   confirmation preset. The note never reaches the customer: it is internal whatever the caller sends.
class Service::AI::Tool::AddInternalNote < Service::AI::Tool
  include Service::AI::Tool::Concerns::ArticleParameters
  include Service::AI::Tool::CreateArticle::Writing

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      article_id:    { type: 'integer', description: 'The internal ID of the note.' },
      ticket_id:     { type: 'integer', description: 'The internal ID of the ticket.' },
      ticket_number: { type: 'string', description: 'The ticket number as shown in Zammad.' },
      url:           { type: 'string', description: 'A link to the ticket in Zammad.' },
    },
    required:   %w[article_id ticket_id ticket_number url],
  }.freeze

  # rubocop:disable Zammad/DetectTranslatableString
  description 'Add an internal note to a ticket. Only agents see it; it is never sent to the customer. Name the ticket ' \
              'by its ticket_number, ticket_id or ticket_url, and give the note as plain text or, with content_type text/html, as HTML.'
  title 'Add internal note'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :write
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents

  # Not the REST API's follow_up?: a user who is the ticket's customer but no agent of its group passes that one, and
  #   would add an agent's note to a group they do not work in.
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true

  # rubocop:disable Zammad/DetectTranslatableString
  parameter :text, type: :string, required: true, description: 'The note, in the format content_type names.'
  content_type_parameter
  time_unit_parameter
  # rubocop:enable Zammad/DetectTranslatableString

  def execute
    write_article(type: 'note', text: argument(:text), content_type: argument(:content_type), time_unit: argument(:time_unit), skip_time_accounting: argument(:skip_time_accounting), internal: true) do |article, _outbound|
      Service::AI::Tool::Runtime::Result.ok(content(article), text: "Added internal note #{article.id} to ticket #{ticket.number}.")
    end
  end

  private

  def content(article)
    {
      article_id:    article.id,
      ticket_id:     ticket.id,
      ticket_number: ticket.number,
      url:           Service::AI::Tool::ObjectLink.url(type: 'Ticket', id: ticket.id),
    }
  end
end
