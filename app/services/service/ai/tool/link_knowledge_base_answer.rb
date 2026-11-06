# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Links a knowledge base answer to a ticket as both views do: linked, from the answer's text to the ticket, which gets
#   the link and needs change access. The answer is named as get_knowledge_base_answer names it and read at the caller's
#   level, so that one the token may not read is not found. An answer's text is linked once to a ticket; another
#   locale's text of the same answer is another one.
class Service::AI::Tool::LinkKnowledgeBaseAnswer < Service::AI::Tool
  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  description 'Link a knowledge base answer to a ticket of Zammad, as the ticket view does. Name the ticket by its ' \
              'ticket_number, ticket_id or ticket_url, and the answer by its answer_id, as a knowledge base search ' \
              'found it, with the locale of its text where the search named one. get_ticket then lists the answer as ' \
              'linked. A link is neither changed nor removed here — the user does that in Zammad.'
  title 'Link knowledge base answer'
  output_schema(
    type:       'object',
    properties: {
      ticket:        Service::AI::Tool::Output::TicketReference::SCHEMA.merge(description: 'The ticket that got the link.'),
      answer:        Service::AI::Tool::Output::KnowledgeBaseAnswer.schema.merge(description: 'The answer, in the locale of the text linked.'),
      linked_before: { type: 'boolean', description: 'The two were linked already; nothing changed.' },
    },
    required:   %w[ticket answer linked_before],
  )
  # rubocop:enable Zammad/DetectTranslatableString
  effect      :write
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents
  # A link is added, never removed, and a second call links nothing more.
  mcp_annotations destructive_hint: false, open_world_hint: false, idempotent_hint: true

  # As the other writes: the ticket's customer who is no agent of its group passes follow_up?, not this.
  loads :ticket, type: ::Ticket, pundit_method: :agent_update_access?, named: true

  parameter :answer_id, type: :integer, required: true, loads: ::KnowledgeBase::Answer,
                        description: 'The ID of the knowledge base answer.' # rubocop:disable Zammad/DetectTranslatableString
  # rubocop:disable-next Zammad/DetectTranslatableString
  parameter :locale, type:        :string,
                     description: 'The locale whose text to link, e.g. "de-de", as a search named it: a preference. Where the answer ' \
                                  'has no text in it, its text in the agent\'s locale, else in the primary one is linked; ' \
                                  'answer.locale in the result says which. Leave it out for the agent\'s own.'

  def self.available?
    ::KnowledgeBase.active.exists?
  end

  def execute
    # The pair's lock, as for two tickets: a call from the knowledge base view links the two the other way round.
    Service::Link::Add.locking_pair(translation, ticket) do
      # Asks nothing, as for a tag or a note, but answers a cancelled or stale request as every write does.
      response = confirmation&.call(required: false, preview:, snapshot: { ticket_id: ticket.id, translation_id: translation.id })
      next response if response

      result(linked_before: linked_before?)
    end
  end

  private

  def translation
    @translation ||= Service::AI::Tool::Lookup::KnowledgeBaseTranslation.of(answer, locale: argument(:locale), user: current_user)
  end

  # @return [Boolean] whether the two were linked already
  def linked_before?
    Service::Link::Add.execute(source: translation, target: ticket, type: 'normal')
    false
  rescue Service::Link::Add::LinkedAlready
    true
  end

  def preview
    "Link knowledge base answer #{answer.id} (#{locale}) to ticket #{ticket.number}?"
  end

  def result(linked_before:)
    text = if linked_before
             "Knowledge base answer #{answer.id} (#{locale}) is linked to ticket #{ticket.number} already; nothing was changed. A " \
               'link is changed or removed in Zammad.'
           else
             "Knowledge base answer #{answer.id} (#{locale}) is now linked to ticket #{ticket.number}."
           end
    text += " It has no text in #{argument(:locale)}, so its #{locale} text was taken." if other_locale?

    Service::AI::Tool::Runtime::Result.ok({ ticket: Service::AI::Tool::Output::TicketReference.of(ticket), answer: answer_reference, linked_before: }, text:)
  end

  def other_locale?
    argument(:locale).present? && !argument(:locale).casecmp?(locale)
  end

  def locale
    translation.kb_locale.system_locale.locale
  end

  def answer_reference
    {
      type:   'KnowledgeBase::Answer',
      id:     answer.id,
      title:  translation.title,
      locale:,
      url:    Service::AI::Tool::ObjectLink.url(type: 'KnowledgeBase::Answer', id: answer.id, locale:),
    }
  end
end
