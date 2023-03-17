# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::MonitoringControllerPolicy < Controllers::ApplicationControllerPolicy

  def health_check?
    token_or_permission?
  end

  def status?
    token_or_permission?
  end

  def amount_check?
    token_or_permission?
  end

  def token?
    permission_and_permission_active?
  end

  def restart_failed_jobs?
    permission_and_permission_active?
  end

  private

  def user_required?
    false
  end

  def token_or_permission?
    if user.present?
      return monitoring_admin?
    end

    valid_token_param?
  end

  def permission_and_permission_active?
    user.present? && monitoring_admin? && permission_active?
  end

  def valid_token_param?
    Setting.get('monitoring_token') == record.params[:token]
  end

  def permission_active?
    Permission.exists?(name: 'admin.monitoring', active: true)
  end

  def monitoring_admin?
    user.permissions?('admin.monitoring')
  end
end
