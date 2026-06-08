# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class UserDevice::NotificationPresenter < SimpleDelegator
  def initialize(user_device, locale)
    super(user_device)
    @locale = locale
  end

  def location
    value = __getobj__.location
    return Translation.translate(@locale, 'Unknown') if value.blank? || value == 'unknown'

    value
  end
end
