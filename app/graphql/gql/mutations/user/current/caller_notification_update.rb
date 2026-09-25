# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::CallerNotificationUpdate < BaseMutation
    description 'Update the caller notification setting of the current user'

    argument :enabled, Boolean, description: 'Whether the caller notification should be shown for incoming calls'

    field :success, Boolean, null: false, description: 'Whether the caller notification setting was updated successfully'

    # Only a phone agent has calls to be notified about. It writes nothing but the caller's own
    #   preference, so this states the intent rather than closing a hole.
    requires_permission 'cti.agent'

    # The `cti` key is shared with the old interface, which reads and writes the same preference.
    def resolve(enabled:)
      user = context.current_user
      user.preferences['cti'] = enabled
      user.save!

      { success: true }
    end
  end
end
