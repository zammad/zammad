module ApplicationController::ChecksMaintainance
  extend ActiveSupport::Concern

  private

  def check_maintenance(user)
    return false if !check_maintenance_only(user)
    raise Exceptions::NotAuthorized, 'Maintenance mode enabled!'
  end

  # check maintenance mode
  def check_maintenance_only(user)
    return false if Setting.get('maintenance_mode') != true
    return false if user.permissions?('admin.maintenance')
    Rails.logger.info "Maintenance mode enabled, denied login for user #{user.login}, it's no admin user."
    true
  end
end
