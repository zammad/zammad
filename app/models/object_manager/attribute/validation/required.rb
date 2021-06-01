# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManager::Attribute::Validation::Required < ObjectManager::Attribute::Validation::Backend

  def validate
    return if value.present?
    return if optional_for_user?

    invalid_because_attribute('is required but missing.')
  end

  private

  def optional_for_user?
    return true if system_user?
    return true if required_for_permissions.blank?
    return false if required_for_permissions.include?('-all-')

    !user.permissions?(required_for_permissions)
  end

  def system_user?
    user_id.blank? || user_id == 1
  end

  def user_id
    @user_id ||= UserInfo.current_user_id
  end

  def user
    @user ||= User.lookup(id: user_id)
  end

  def required_for_permissions
    @required_for_permissions ||= begin
      attribute.screens[action]&.each_with_object([]) do |(permission, config), result|
        result.push(permission) if config[:required].present?
      end
    end
  end

  def action
    return :edit if record.persisted?

    attribute.screens.keys.find { |e| e.start_with?('create') }
  end
end
