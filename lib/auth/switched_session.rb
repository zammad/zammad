# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A session an admin switched into another user from stays the admin's, but is served as the
#   switched-to user: SessionsController#switch_to_user moves that user into the session's
#   'user_id' and remembers the admin in 'switched_from_user_id'. Checking the account such a
#   session is served as therefore says nothing about the account that owns it, and switching
#   back is not required to keep working - so without this check a revoked admin would work on as
#   the user they switched into, indefinitely.
#
# It is asked wherever the authentication prerequisites are applied (see
#   ApplicationController::Authenticates#authentication_check_prerequesits), so that all entry
#   points agree, and it complements dropping the stored session itself (see
#   User::TerminatesSessions): the session of a switched admin is served from a session record
#   for as long as one exists, and from a copy of it afterwards on the legacy transport.
module Auth::SwitchedSession

  # Deliberately does not log a denial, for the same reason Auth::MaintenanceMode does not: this
  #   is asked per request, per event and per run of a client loop.
  #
  # @param switched_from_user_id [Integer, String, nil] present while an admin is switched to
  #   another user, and the account that owns the session in that case.
  #
  # @return [Boolean] whether the account that switched to another user has been revoked, which
  #   is the case for a deactivated as well as for a deleted one.
  def self.revoked?(switched_from_user_id)
    return false if switched_from_user_id.blank?

    !User.find_by(id: switched_from_user_id)&.active?
  end
end
