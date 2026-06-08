# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::MonitoringControllerPolicy < Controllers::ApplicationControllerPolicy
  USER_REQUIRED = false

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
    monitoring_admin?
  end

  def restart_failed_jobs?
    monitoring_admin?
  end

  private

  def token_or_permission?
    monitoring_admin? || valid_token_param?
  end

  def valid_token_param?
    Setting.get('monitoring_token') == record.params[:token]
  end

  def monitoring_admin?
    user.present? && user.permissions?('admin.monitoring')
  end
end
