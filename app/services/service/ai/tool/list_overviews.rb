# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Lists the overviews the user works from — the saved ticket lists an admin set up for the team —, as the overview list
#   of Zammad shows them: in the user's own order, each with the count of its tickets. A user has a handful, so the list
#   comes whole. The harness gets it once a conversation can start from a list.
class Service::AI::Tool::ListOverviews < Service::AI::Tool
  # Written for the model, like every text a tool returns, so not translated.
  OUTPUT_SCHEMA = {
    type:       'object',
    properties: {
      overviews: { type: 'array', items: Service::AI::Tool::Output::Overview::SCHEMA },
    },
    required:   %w[overviews],
  }.freeze

  # rubocop:disable Zammad/DetectTranslatableString
  description 'List the user\'s overviews in Zammad: the saved ticket lists an admin set up for the team, such as ' \
              '"My Assigned Tickets" or "Escalated Tickets", in the user\'s order, each with the count of its tickets ' \
              'and its link. Call it when the user asks which lists there are or how many tickets wait where. ' \
              'get_overview_tickets reads the tickets of one, by its ID or by its name, also without this list first. ' \
              'The user\'s own open tickets are search_tickets with owner "me" and state_type_category "open".'
  title 'List overviews'
  # rubocop:enable Zammad/DetectTranslatableString
  output_schema OUTPUT_SCHEMA
  effect      :read
  permission  'ticket.agent'
  offered_in  :mcp
  audiences   :human_agents

  def execute
    Service::AI::Tool::Runtime::Result.ok({ overviews: rows.map(&:content) }, text:)
  end

  private

  def rows
    @rows ||= Service::AI::Tool::Lookup::UserOverviews.new(current_user).rows # rubocop:disable Zammad/ForbidCallingServiceDirectly
  end

  def text
    return 'Overviews: none — the user has no overview in Zammad.' if rows.empty? # rubocop:disable Zammad/DetectTranslatableString

    ['Overviews, in the user\'s order:', *rows.map(&:text), 'get_overview_tickets reads the tickets of one by its ID or name.'].join("\n") # rubocop:disable Zammad/DetectTranslatableString
  end
end
