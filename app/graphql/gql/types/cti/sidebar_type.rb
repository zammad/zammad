# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  # Resolved over the caller log scope of the current user, so each field costs only its own query.
  class Cti::SidebarType < Gql::Types::BaseObject
    description 'What the navigation entry of the CTI integration shows for the current user'

    field :unhandled_count, Integer, null: false, description: 'Calls not marked as done, across the whole caller log of the user'
    field :ringing_calls, [Gql::Types::Cti::LogType, { null: false }], null: false, description: 'Calls still ringing among the entries the caller log shows, newest first'

    # Unlike the old counter, not cut off at the view limit: a missed call stays unhandled
    #   however many calls came in after it.
    def unhandled_count
      object.unhandled.count
    end

    # The old navigation reads its widgets from the caller log list, which stops at the
    #   configured view limit; the same window keeps a stale ringing entry from showing forever.
    def ringing_calls
      object.within_view_limit.ringing
    end
  end
end
