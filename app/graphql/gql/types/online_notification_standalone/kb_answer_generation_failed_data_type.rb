# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::OnlineNotificationStandalone
  class KbAnswerGenerationFailedDataType < Gql::Types::BaseObject
    description 'Data payload for knowledge base answer generation failure notifications'

    field :error_message, String, null: false
    field :ticket_title, String, null: false
  end
end
