# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::ChecksMaintenance
  extend ActiveSupport::Concern

  private

  def in_maintenance_mode?(user)
    return false if !Auth::MaintenanceMode.blocks?(user, switched_from_user_id: session[:switched_from_user_id])

    Rails.logger.info "Maintenance mode enabled, denied login for user #{user.login}, it's no admin user."
    true
  end
end
