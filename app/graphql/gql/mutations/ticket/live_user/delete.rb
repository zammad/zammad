# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Ticket::LiveUser::Delete < Ticket::LiveUser::Base
    description 'Deletes the desired live user entry.'

    field :success, Boolean, null: false, description: 'Was the live user entry deletion successful?'

    def resolve(ticket:, app:)
      taskbar_key = taskbar_key(ticket.id)

      taskbar_item(taskbar_key, app)&.destroy!

      { success: true }
    end
  end
end
