# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::ChecksMaintenance
  extend ActiveSupport::Concern

  private

  def in_maintenance_mode?(user)
    return false if !maintenance_mode_active?
    return false if user.permissions?('admin.maintenance')
    return false if switched_from_maintenance_admin?

    Rails.logger.info "Maintenance mode enabled, denied login for user #{user.login}, it's no admin user."
    true
  end

  def maintenance_mode_active?
    Setting.get('maintenance_mode') == true || Setting.get('import_mode') == true
  end

  # An impersonated session is only as privileged as the user who switched.
  def switched_from_maintenance_admin?
    return false if session[:switched_from_user_id].blank?

    User.find_by(id: session[:switched_from_user_id])&.permissions?('admin.maintenance') || false
  end
end
