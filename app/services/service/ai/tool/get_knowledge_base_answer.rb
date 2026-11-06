# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads one knowledge base answer the user may read, by its ID — one a search found or one linked to the ticket — in
#   the locale asked for, else in the user's, falling back as GraphQL's answer type does: to the primary locale, then
#   any. The answer is a row as in every tool, with its text below it (Service::AI::Tool::Output).
class Service::AI::Tool::GetKnowledgeBaseAnswer < Service::AI::Tool
  TEXT_LENGTH = 8_000

  # Written for the model, like every text a tool returns, so not translated.
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: { answer: Service::AI::Tool::Output::KnowledgeBaseAnswer.part_schema },
    required:   %w[answer],
  }.freeze

  description 'Read one knowledge base answer of Zammad in full, by its ID: one a knowledge base search found, or one ' \
              'get_ticket lists as linked to a ticket. In the locale asked for, else in the user\'s, else in the ' \
              'knowledge base\'s primary one.'
  # rubocop:disable-next Zammad/DetectTranslatableString
  title 'Get knowledge base answer'
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :harness, :mcp
  audiences   :human_agents

  parameter :answer_id, type: :integer, required: true, loads: ::KnowledgeBase::Answer,
                        description: 'The ID of the knowledge base answer.' # rubocop:disable Zammad/DetectTranslatableString
  parameter :locale, type:        :string,
                     description: 'The locale of its text, e.g. "de-de", as a search or the ticket named it. Leave it out for the agent\'s own.' # rubocop:disable Zammad/DetectTranslatableString

  def self.available?
    ::KnowledgeBase.active.exists?
  end

  def execute
    Service::AI::Tool::Runtime::Result.ok({ answer: answer_part.content }, text: answer_part.text)
  end

  private

  def answer_part
    @answer_part ||= Service::AI::Tool::Output::KnowledgeBaseAnswer.part(
      translation,
      length:    TEXT_LENGTH,
      edited_at: (translation.edited_at if field_visible?(translation, :edited_at)),
    )
  end

  def translation
    @translation ||= Service::AI::Tool::Lookup::KnowledgeBaseTranslation.of(answer, locale: argument(:locale), user: current_user)
  end
end
