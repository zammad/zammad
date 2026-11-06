# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# An organization in a tool's result, such as a ticket's customer's: a reference to the organization's own page, not
#   its whole record.
class Service::AI::Tool::Output::Organization < Service::AI::Tool::Output
  # Written for the model, like every text a tool returns, so not translated.
  SCHEMA = {
    type:       'object',
    properties: {
      type: { const: 'Organization' },
      id:   { type: 'integer' },
      name: { type: 'string' },
      url:  { type: 'string', description: 'Link to the organization in Zammad.' }, # rubocop:disable Zammad/DetectTranslatableString
    },
    required:   %w[type id name],
  }.freeze

  class << self
    def row(organization)
      build_part(
        content: { type: 'Organization', id: organization.id, name: organization.name },
        text:    AI::PromptText.xml_text(organization.name.to_s.squish),
      )
    end
  end
end
