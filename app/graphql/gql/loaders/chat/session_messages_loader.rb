# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Loads the messages of the listed sessions in one query, oldest first.
class Gql::Loaders::Chat::SessionMessagesLoader < GraphQL::Batch::Loader
  def perform(session_ids)
    ::Chat::Message
      .where(chat_session_id: session_ids)
      .reorder(created_at: :asc, id: :asc)
      .group_by(&:chat_session_id)
      .each { |session_id, messages| fulfill(session_id, messages) }

    session_ids.each { |session_id| fulfill(session_id, []) if !fulfilled?(session_id) }
  end
end
