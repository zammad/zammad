# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# An overview in a tool's result: one of the saved ticket lists the user works from, as the overview list shows it — its
#   name in the user's language and the count of its tickets.
class Service::AI::Tool::Output::Overview < Service::AI::Tool::Output
  # Written for the model, like every text a tool returns, so not translated.
  # rubocop:disable-next Zammad/DetectTranslatableString
  SCHEMA = {
    type:       'object',
    properties: {
      type:         { const: 'Overview' },
      id:           { type: 'integer' },
      name:         { type: 'string', description: 'The name the user sees, in the user\'s language.' },
      stored_name:  { type: 'string', description: 'The name as an admin stored it, where the user sees a translation.' },
      ticket_count: { type: 'integer', description: 'How many tickets the user may see in the overview.' },
      url:          { type: 'string', description: 'Link to the overview in Zammad.' },
    },
    required:   %w[type id name ticket_count],
  }.freeze

  class << self
    # The overview as a row: one line of its facts. Its name is an admin's, set up for the team, so a fact like a
    #   group's name.
    def row(overview, user:, ticket_count:)
      name   = name_for(overview, user)
      stored = overview.name if name != overview.name

      build_part(
        content: { type: 'Overview', id: overview.id, name:, stored_name: stored, ticket_count: }.compact,
        text:    AI::PromptText.xml_text(["Overview #{overview.id}", "#{name}#{" (#{stored})" if stored}", tickets(ticket_count)].join(' · ').squish),
      )
    end

    # The seeded overviews are named by source strings, which the interfaces translate; an admin's own keeps its name.
    def name_for(overview, user)
      Translation.translate(user.locale, overview.name)
    end

    private

    def tickets(count)
      case count
      when 0 then 'no tickets'
      when 1 then '1 ticket'
      else "#{count} tickets"
      end
    end
  end
end
