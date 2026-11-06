# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Lists the tags of the installation, as the REST API's tag search does for an agent: by name only, the most used first,
#   narrowed by a part of the name. set_ticket_tags matches names on its own, so a client needs it only to ask which tags
#   there are.
class Service::AI::Tool::ListTags < Service::AI::Tool
  DEFAULT_LIMIT = 20
  MAX_LIMIT     = 50

  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable Zammad/DetectTranslatableString
  description 'List the tags that exist in Zammad, the most used first, optionally only those whose name contains query. ' \
              'Call it when the user asks which tags there are or which fit. set_ticket_tags needs no list first: it ' \
              'matches the names it gets and names the closest tags for one that does not exist.'
  title 'List tags'
  parameter :query, type: :string, description: 'A part of the tag name, such as "bill".'
  parameter :limit, type: :integer, minimum: 1, maximum: MAX_LIMIT, default: DEFAULT_LIMIT, description: 'How many tags to list.'
  parameter :cursor, type: :string, description: 'next_cursor of the previous result, for the next tags.'
  output_schema(
    type:       'object',
    properties: {
      tags:        { type: 'array', items: { type: 'string' } },
      total:       { type: 'integer', description: 'How many tags match, on every page.' },
      next_cursor: { type: 'string', description: 'Pass it as cursor, with the same query, for the next tags.' },
    },
    required:   %w[tags total],
  )
  # rubocop:enable Zammad/DetectTranslatableString
  effect      :read
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents

  def execute
    offset = cursor_offset
    return Service::AI::Tool::Runtime::Result.error('invalid_arguments', "cursor is no next_cursor of this list. #{CURSOR_HINT} the first tag.") if offset.nil?

    names   = ranked.offset(offset).limit(argument(:limit) + 1).pluck(:name)
    page    = names.first(argument(:limit))
    content = { tags: page, total: matching.count, next_cursor: (next_cursor_at(offset + page.size) if names.size > page.size) }.compact

    Service::AI::Tool::Runtime::Result.ok(content, text: text(content))
  end

  private

  def matching
    query = argument(:query).to_s.strip
    return Tag::Item.all if query.empty?

    Tag::Item.where('tag_items.name_downcase LIKE ?', "%#{SqlHelper.quote_like(query.downcase)}%")
  end

  # The ID breaks ties, so that pages neither repeat nor skip a tag.
  def ranked
    matching.left_outer_joins(:tags).group(:id).reorder(Arel.sql('COUNT(tags.id) DESC, tag_items.name ASC, tag_items.id ASC'))
  end

  # rubocop:disable-next Zammad/DetectTranslatableString
  def text(content)
    return 'Tags: none match.' if content[:tags].empty?

    more = content[:next_cursor] ? "More follow: call again with the same query and cursor \"#{content[:next_cursor]}\"." : 'No more follow.'

    ["Tags, the most used first (#{content[:total]} match):", content[:tags].join(', '), more].join("\n")
  end
end
