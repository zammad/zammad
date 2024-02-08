# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::FilterPermissionAssignments < Service::BaseWithCurrentUser

  SUFFIXES = %w[_ids s].freeze
  MODELS = %w[Role Group].freeze

  def execute(user_data:)
    return if current_user.permissions?('admin.user')

    user_data.deep_stringify_keys! if user_data.is_a?(Hash)

    # Regular agents are not allowed to set Groups and Roles.
    MODELS.each do |model|
      SUFFIXES.each do |suffix|
        attribute = "#{model.downcase}#{suffix}"
        values    = user_data[attribute]
        user_data.delete(attribute) if !values.nil?
      end
    end
  end

end
