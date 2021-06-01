# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Controllers::SettingsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.*')

  def show?
    user.permissions!('admin.*')
    authorized_for_setting?(:show?)
  end

  def update?
    updateable?
  end

  def update_image?
    updateable?
  end

  private

  def setting
    @setting ||= Setting.lookup(id: record.params[:id])
  end

  def authorized_for_setting?(query)
    Pundit.authorize(user, setting, query)
    true
  rescue Pundit::NotAuthorizedError
    not_authorized("required #{setting.preferences[:permission].inspect}")
  end

  def updateable?
    return false if !user.permissions?('admin.*')
    return false if !authorized_for_setting?(:update?)

    service_enabled?
  end

  def service_enabled?
    return true if !Setting.get('system_online_service')
    return true if !setting.preferences[:online_service_disable]

    not_authorized('service disabled')
  end
end
