# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Chat::SessionStateType < BaseEnum
    description 'State of a chat session'

    value 'waiting', 'In the queue of its topic, not accepted by an agent yet'
    value 'running', 'Accepted by an agent and in progress'
    value 'closed', 'Ended'
  end
end
