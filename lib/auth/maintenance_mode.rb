# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Maintenance mode locks out everybody without maintenance permissions. It is applied when a
#   user is authenticated over HTTP, when their session is restored on one of the real-time
#   transports, and while such a session is served, so that all entry points agree on who is
#   locked out.
#
# It does not terminate connections that are already established when the setting is switched
#   on: an ActionCable connection ends on its next restore, a legacy one on the next run of its
#   push loop. Established real-time connections are torn down for a deactivated or deleted
#   account only (see User::TerminatesSessions).
#
# It does not log a client out either. The Vue front end does that itself, however the setting
#   was toggled, since Setting#broadcast_frontend triggers a config update on every save. A
#   legacy tab only reacts to the 'maintenance' event that the legacy admin interface sends (see
#   Sessions::Event::Maintenance), so one left open while the setting is changed elsewhere keeps
#   its rendered state until its next request is denied.
module Auth::MaintenanceMode

  # Deliberately does not log a denial: this is asked per event and per run of a client loop, so
  #   a line per denial would flood the log for as long as maintenance mode is on. The HTTP entry
  #   point logs its own denial instead (see ApplicationController::ChecksMaintenance).
  #
  # @param user [User] the user whose access is to be checked.
  # @param switched_from_user_id [Integer, String, nil] present while an admin is switched to
  #   another user, which keeps that session working if that admin has maintenance permissions.
  #
  # @return [Boolean] whether maintenance mode denies access to the given user.
  def self.blocks?(user, switched_from_user_id: nil)
    return false if !active?
    return false if user.permissions?('admin.maintenance')

    !switched_from_maintenance_admin?(switched_from_user_id)
  end

  def self.active?
    Setting.get('maintenance_mode') == true || Setting.get('import_mode') == true
  end

  # An impersonated session is only as privileged as the user who switched.
  def self.switched_from_maintenance_admin?(switched_from_user_id)
    return false if switched_from_user_id.blank?

    User.find_by(id: switched_from_user_id)&.permissions?('admin.maintenance') || false
  end
  private_class_method :switched_from_maintenance_admin?
end
