# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A knowledge base answer in a tool's result, named by the answer's ID and the locale of its text, by which the
#   desktop view opens it.
class Service::AI::Tool::Output::KnowledgeBaseAnswer < Service::AI::Tool::Output
  CATEGORY_SEPARATOR = ' / '.freeze

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  CATEGORY_SCHEMA = {
    type:       'object',
    properties: {
      id:   { type: 'integer' },
      path: { type: 'string', description: 'The titles of the category and the categories above it, the top one first, as in "Setup / Email".' },
    },
    required:   %w[id path],
  }.freeze

  SCHEMA = {
    type:       'object',
    properties: {
      type:     { const: 'KnowledgeBase::Answer' },
      id:       { type: 'integer' },
      title:    { type: 'string' },
      locale:   { type: 'string' },
      category: CATEGORY_SCHEMA,
      url:      { type: 'string', description: 'Link to the answer in Zammad.' },
    },
    required:   %w[type id title locale category],
  }.freeze
  # rubocop:enable Zammad/DetectTranslatableString

  # The facts and the text of #part.
  # rubocop:disable-next Zammad/DetectTranslatableString
  PART_PROPERTIES = {
    visibility:  { enum: %w[public internal draft archived], description: 'public: customers may read the answer too.' },
    edited_at:   { type: 'string', format: 'date-time' },
    tags:        { type: 'array', items: { type: 'string' } },
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
    # @param category [Hash, nil] the answer's category as #categories gives it, which rows of many answers load together
    # @param content [Hash] the tool's own facts for the content, such as how the answer is linked
    # @param facts [Array<String, nil>] the same facts for the line
    def row(translation, category: nil, content: {}, facts: [])
      locale     = translation.kb_locale.system_locale.locale
      category ||= categories([translation]).fetch(translation.id)

      build_row(
        content: { type: 'KnowledgeBase::Answer', id: translation.answer_id, title: translation.title, locale:, category:, **content },
        facts:   ["Knowledge base answer #{translation.answer_id}", locale, "category #{category[:path]}", *facts],
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
    # @param category [Hash, nil] as #row takes it
    # @param tags [Array<String>, nil] the answer's tags, where the tool shows them
    # @param content [Hash] the tool's own facts for the content, such as an identifier the text contains
    # @param facts [Array<String, nil>] the same facts for the line
    def part(translation, length:, passage: nil, edited_at: nil, category: nil, tags: nil, content: {}, facts: [])
      visibility = translation.answer.visible? ? 'public' : translation.answer.visibility.to_s
      shown      = cut(translation.content&.body_text_only.to_s.strip, length:, passage:)
      answer_row = row(
        translation,
        category:,
        content:  { visibility:, edited_at:, tags:, **content, text: shown.text, truncated: shown.truncated, part: shown.part, full_length: shown.full_length }.compact,
        facts:    [visibility, ("updated #{time(edited_at)}" if edited_at), ("tags: #{tags.join(', ')}" if tags.present?), *facts],
      )

      answer_row.with(text: [answer_row.text, AI::PromptText.marked_text(shown.text, source: 'knowledge_base', answer: translation.answer_id, cut: shown.note)].join("\n"))
    end

    # The category of each answer, by the ID of its text: its ID and its path, titled in the locale of the text as
    #   the desktop view's breadcrumb shows it, the categories above it included. Two queries for any number of texts.
    #
    # @param translations [Array<KnowledgeBase::Answer::Translation>]
    # @return [Hash{Integer => Hash}]
    def categories(translations)
      return {} if translations.empty?

      category_ids = translations.map { |translation| translation.answer.category_id }.uniq
      parents      = category_parents(category_ids)
      trails       = category_ids.index_with { |id| category_trail(id, parents) }
      titles       = category_titles(translations.flat_map { |translation| trails[translation.answer.category_id].map { |id| [id, translation.kb_locale_id] } })

      translations.to_h do |translation|
        trail = trails[translation.answer.category_id]
        path  = trail.filter_map { |id| titles[[id, translation.kb_locale_id]] }.join(CATEGORY_SEPARATOR)

        [translation.id, { id: trail.last, path: }]
      end
    end

    # The tags of each answer, by its ID, as KnowledgeBase::Answer#tag_list reads them, from one query.
    #
    # @param answer_ids [Array<Integer>]
    # @return [Hash{Integer => Array<String>}]
    def tags(answer_ids)
      ::Tag
        .joins(:tag_item, :tag_object)
        .where(tag_objects: { name: ::KnowledgeBase::Answer.name }, o_id: answer_ids)
        .reorder('tags.id, tag_items.name')
        .pluck('tags.o_id', 'tag_items.name')
        .each_with_object(answer_ids.index_with { [] }) { |(id, name), lists| lists[id] << name }
    end

    private

    # The parent of each given category and of each category above them, as #self_with_parents walks the tree.
    def category_parents(category_ids)
      ::KnowledgeBase::Category
        .with_recursive_tree_cte(direction: :up, seed: ::KnowledgeBase::Category.where(id: category_ids))
        .reorder(nil)
        .distinct
        .pluck(:id, :parent_id)
        .to_h
    end

    # The category and the ones above it, the top one first; a loop in the tree ends the walk.
    def category_trail(id, parents)
      trail = []

      while id && trail.exclude?(id)
        trail.unshift(id)
        id = parents[id]
      end

      trail
    end

    def category_titles(pairs)
      ::KnowledgeBase::Category.preferred_translations_for(pairs).transform_values { |translation| translation&.title }
    end
  end
end
