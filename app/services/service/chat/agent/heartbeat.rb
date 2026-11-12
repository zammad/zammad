# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The counterpart of the legacy chat_status_agent poll. Only the timestamp moves: a flag written back
#   here, even one read a moment ago, would undo a toggle made in either UI in the meantime.
class Service::Chat::Agent::Heartbeat < Service::Base
  requires_current_user!

  def execute
    touched = ::Chat::Agent.where(updated_by_id: current_user.id).touch_all # rubocop:disable Rails/SkipsModelValidations

    ::Chat::Agent.create!(active: false, updated_by_id: current_user.id, created_by_id: current_user.id) if touched.zero?

    true
  end
end
