# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A user in a tool's result, such as a ticket's customer or owner: a reference to the user's own page, not the user's
#   whole record.
class Service::AI::Tool::Output::User < Service::AI::Tool::Output
  # Written for the model, like every text a tool returns, so not translated.
  SCHEMA = {
    type:       'object',
    properties: {
      type:  { const: 'User' },
      id:    { type: 'integer' },
      name:  { type: 'string', description: 'The user\'s full name, as the user or an agent wrote it.' }, # rubocop:disable Zammad/DetectTranslatableString
      email: { type: 'string' },
      url:   { type: 'string', description: 'Link to the user in Zammad.' }, # rubocop:disable Zammad/DetectTranslatableString
    },
    required:   %w[type id name],
  }.freeze

  class << self
    # The user as a row: its content, and its name with the email where there is one, for a line of facts.
    def row(user)
      email = user.email.presence

      build_part(
        content: { type: 'User', id: user.id, name: user.fullname, email: }.compact,
        text:    AI::PromptText.xml_text([user.fullname, ("(#{email})" if email)].compact.join(' ').squish),
      )
    end
  end
end
