# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A knowledge base answer in a tool's result, named by the answer's ID and the locale of its text, by which the
#   desktop view opens it.
class Service::AI::Tool::Output::KnowledgeBaseAnswer < Service::AI::Tool::Output
  # Written for the model, like every text a tool returns, so not translated.
  SCHEMA = {
    type:       'object',
    properties: {
      type:   { const: 'KnowledgeBase::Answer' },
      id:     { type: 'integer' },
      title:  { type: 'string' },
      locale: { type: 'string' },
      url:    { type: 'string', description: 'Link to the answer in Zammad.' }, # rubocop:disable Zammad/DetectTranslatableString
    },
    required:   %w[type id title locale],
  }.freeze

  # The facts and the text of #part.
  # rubocop:disable-next Zammad/DetectTranslatableString
  PART_PROPERTIES = {
    visibility:  { enum: %w[public internal draft archived], description: 'public: customers may read the answer too.' },
    edited_at:   { type: 'string', format: 'date-time' },
    text:        { type: 'string', description: 'The answer\'s text, as the knowledge base\'s editors wrote it.' },
    truncated:   { type: 'boolean' },
    part:        { enum: %w[passage start], description: 'Which part of a cut text is shown: the passage that matched, or the start.' },
    full_length: { type: 'integer', description: 'The length of a cut text in full, in characters.' },
  }.freeze

  class << self
    # @param properties [Hash] the schemas of the tool's own facts in the row, such as how the answer is linked
    def schema(**properties)
      SCHEMA.merge(properties: SCHEMA[:properties].merge(properties))
    end

    # The schema of #part, with the tool's own facts.
    def part_schema(**properties)
      schema(**PART_PROPERTIES, **properties).merge(required: SCHEMA[:required] + %w[visibility text truncated])
    end

    # The answer as a row: one line of its facts, and its title below it, marked as the knowledge base's.
    #
    # @param translation [KnowledgeBase::Answer::Translation]
    # @param content [Hash] the tool's own facts for the content, such as how the answer is linked
    # @param facts [Array<String, nil>] the same facts for the line
    def row(translation, content: {}, facts: [])
      locale = translation.kb_locale.system_locale.locale

      build_row(
        content: { type: 'KnowledgeBase::Answer', id: translation.answer_id, title: translation.title, locale:, **content },
        facts:   ["Knowledge base answer #{translation.answer_id}", locale, *facts],
        title:   translation.title,
        source:  'knowledge_base',
      )
    end

    # The answer as a row with its text below it, marked as the knowledge base's. A text longer than the given length
    #   is shown by the passage that matched a search where there is one, by its start otherwise, and says how much of
    #   it is shown.
    #
    # @param passage [String, nil] the part of the text that matched a search
    # @param edited_at [Time, nil] when the text was last edited, where the user may see it
    # @param content [Hash] the tool's own facts for the content, such as an identifier the text contains
    # @param facts [Array<String, nil>] the same facts for the line
    def part(translation, length:, passage: nil, edited_at: nil, content: {}, facts: [])
      visibility = translation.answer.visible? ? 'public' : translation.answer.visibility.to_s
      shown      = cut(translation.content&.body_text_only.to_s.strip, length:, passage:)
      answer_row = row(
        translation,
        content: { visibility:, edited_at:, **content, text: shown.text, truncated: shown.truncated, part: shown.part, full_length: shown.full_length }.compact,
        facts:   [visibility, ("updated #{time(edited_at)}" if edited_at), *facts],
      )

      answer_row.with(text: [answer_row.text, AI::PromptText.marked_text(shown.text, source: 'knowledge_base', answer: translation.answer_id, cut: shown.note)].join("\n"))
    end
  end
end
