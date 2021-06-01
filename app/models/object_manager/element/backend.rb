# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ObjectManager::Element::Backend

  attr_reader :user, :attribute, :record

  def initialize(user:, attribute:, record:)
    @user      = user
    @attribute = attribute
    @record    = record
  end

  def visible?
    return true if attribute.data_option[:permission].blank?
    return false if user.blank?

    attribute.data_option[:permission].any? do |permission|
      authorized?(permission)
    end
  end

  def authorized?(permission)
    user.permissions?(permission)
  end

  def data
    data = default_data

    data[:screen] = screens if attribute.screens.present?

    return data if attribute.data_option.blank?

    data.merge(attribute.data_option.symbolize_keys)
  end

  def default_data
    {
      name:    attribute.name,
      display: attribute.display,
      tag:     attribute.data_type,
      #:null     => attribute.null,
    }
  end

  def screens
    attribute.screens.transform_values do |permission_options|
      screen_value(permission_options)
    end
  end

  def screen_value(permission_options)
    return permission_options['-all-'] if permission_options['-all-']
    return {} if user.blank?

    screen_permission_options(permission_options)
  end

  def screen_permission_options(permission_options)
    booleans = [true, false]
    permission_options.each_with_object({}) do |(permission, options), result|

      next if !authorized?(permission)

      options.each do |key, value|
        next if booleans.include?(result[key]) && !value

        result[key] = value
      end
    end
  end
end
