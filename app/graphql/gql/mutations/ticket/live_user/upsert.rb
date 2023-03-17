# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  # At the moment the implementaion is more or less only for the "live" user handling in the
  # mobile view, because we have no "real" taskbar in the mobile view.
  # For the future we should refactor the complete taskbar handling (e.g. split taskbar/auto-save/live-user) handling.
  class Ticket::LiveUser::Upsert < Ticket::LiveUser::Base
    description 'Updates the current live user entry. If no matching live user entry is found, a new live user entry for the current user and ticket will be created.'

    argument :editing, Boolean, description: 'Indicates if the user is currently editing the ticket.'

    field :success, Boolean, null: false, description: 'Did we succeed to insert/update the live user entry?'

    def resolve(ticket:, app:, editing:)
      taskbar_key = taskbar_key(ticket.id)
      taskbar_item = taskbar_item(taskbar_key, app)

      if taskbar_item.present?
        taskbar_item.update!({ state: { editing: editing } })
      else
        Taskbar.create!({
                          user_id:  context.current_user.id,
                          active:   true,
                          app:      app,
                          key:      taskbar_key,
                          callback: 'TicketDetailView',
                          params:   { ticket_id: ticket.id },
                          state:    { editing: editing },
                          prio:     100,
                        })
      end

      { success: true }
    end
  end
end
