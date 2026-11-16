# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Reads one knowledge base answer the user may read, by its ID — one a search found or one linked to the ticket — in
#   the locale asked for, else in the user's, falling back as GraphQL's answer type does: to the primary locale, then
#   any. In two layers, as get_ticket reads a ticket: "detailed" with the text, the files and the tickets linked to the
#   text; "concise" with the start of the text and the counts only. The answer is a row as in every tool, with its
#   text below it (Service::AI::Tool::Output).
class Service::AI::Tool::GetKnowledgeBaseAnswer < Service::AI::Tool
  TEXT_LENGTH    = { 'detailed' => 8_000, 'concise' => 300 }.freeze
  REFERENCE_ROWS = 10

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      answer:         Service::AI::Tool::Output::KnowledgeBaseAnswer.part_schema,
      counts:         {
        type:       'object',
        properties: { attachments: { type: 'integer' }, linked_tickets: { type: 'integer' } },
        required:   %w[attachments linked_tickets],
      },
      attachments:    {
        type:        'array',
        items:       {
          type:       'object',
          properties: {
            filename:     { type: 'string' },
            content_type: { type: 'string' },
            size:         { type: 'integer', description: 'In bytes.' },
            url:          { type: 'string', description: 'Link to download the file in Zammad, for the person.' },
          },
          required:   %w[filename url],
        },
        description: 'The answer\'s files, in the detailed layer.',
      },
      linked_tickets: { type: 'array', items: Service::AI::Tool::Output::Ticket::SCHEMA, description: 'The tickets linked to the text, in the detailed layer.' },
    },
    required:   %w[answer counts],
  }.freeze

  description 'Read one knowledge base answer of Zammad in full, by its ID: one a knowledge base search found, or one ' \
              'get_ticket lists as linked to a ticket. In the locale asked for, else in the user\'s, else in the ' \
              'knowledge base\'s primary one. With its category, tags, files and the tickets linked to it; with ' \
              'response_format "concise" only the start of the text and how many files and tickets there are.'
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
  parameter :response_format, type: :string, enum: %w[detailed concise], default: 'detailed',
                              description: 'detailed: the text, the files and the linked tickets. concise: the start of ' \
                                           'the text and how many files and linked tickets there are.'

  def self.available?
    ::KnowledgeBase.active.exists?
  end

  def execute
    Service::AI::Tool::Runtime::Result.ok(content, text:)
  end

  private

  def content
    @content ||= {
      answer:         answer_part.content,
      counts:         { attachments: attachments.size, linked_tickets: linked_tickets.size },
      attachments:    (attachments.first(REFERENCE_ROWS).map { |file| file_facts(file) } if !concise?),
      linked_tickets: (linked_ticket_rows.map(&:content) if !concise?),
    }.compact
  end

  def concise?
    argument(:response_format) == 'concise'
  end

  def answer_part
    @answer_part ||= Service::AI::Tool::Output::KnowledgeBaseAnswer.part(
      translation,
      length:    TEXT_LENGTH.fetch(argument(:response_format)),
      edited_at: (translation.edited_at if field_visible?(translation, :edited_at)),
      tags:      answer.tag_list,
    )
  end

  def translation
    @translation ||= Service::AI::Tool::Lookup::KnowledgeBaseTranslation.of(answer, locale: argument(:locale), user: current_user)
  end

  # The answer's own files, as the desktop view lists them; the images in the text are part of the text.
  def attachments
    @attachments ||= answer.attachments_sorted
  end

  def file_facts(file)
    {
      filename:     file.filename,
      content_type: Service::AI::Tool::StoredFile.mime_type(file).presence,
      size:         file.size.presence&.to_i,
      url:          file_url(file),
    }.compact
  end

  # The download the knowledge base views use, which checks the answer's access.
  def file_url(file)
    "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/api/v1/attachments/#{file.id}?disposition=attachment"
  end

  # Links belong to an answer's text in one locale, as the knowledge base's sidebar lists them; only tickets the user
  #   may see.
  def linked_tickets
    @linked_tickets ||= Service::Link::List
      .with_current_user(current_user)
      .execute(object: translation, target_type: 'Ticket')
      .sort_by { |link| -link[:item].id }
  end

  def linked_ticket_rows
    @linked_ticket_rows ||= begin
      shown = linked_tickets.first(REFERENCE_ROWS)
      ActiveRecord::Associations::Preloader.new(records: shown.pluck(:item), associations: %i[customer organization]).call

      shown.map { |link| Service::AI::Tool::Output::Ticket.row(link[:item]) }
    end
  end

  def text
    [answer_part.text, counts_text, *(concise? ? [] : [*attachment_texts, *linked_ticket_texts])].compact.join("\n\n")
  end

  def counts_text
    return if !concise?

    counts = "Files: #{attachments.size}. Linked tickets: #{linked_tickets.size}."
    counts += ' response_format "detailed" lists them.' if attachments.any? || linked_tickets.any?

    AI::PromptText.xml_text(counts)
  end

  def attachment_texts
    return [] if attachments.empty?

    names = attachments.first(REFERENCE_ROWS).map { |file| file_text(file_facts(file)) }

    [AI::PromptText.xml_text("Files: #{shown_count(attachments)}\n#{names.join("\n")}")]
  end

  def file_text(facts)
    details = [facts[:content_type], (ActiveSupport::NumberHelper.number_to_human_size(facts[:size]) if facts[:size])].compact

    "#{facts[:filename]}#{" (#{details.join(', ')})" if details.any?}; link for the person: #{facts[:url]}"
  end

  def linked_ticket_texts
    return [] if linked_tickets.empty?

    [
      AI::PromptText.xml_text("Linked tickets: #{shown_count(linked_tickets)}"),
      *linked_ticket_rows.map(&:text),
      Service::AI::Tool::Output::Ticket::LISTED_NOTE,
    ]
  end

  def shown_count(list)
    list.size > REFERENCE_ROWS ? "#{list.size}, the first #{REFERENCE_ROWS} below." : "#{list.size}."
  end
end
