# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::User::FilterPermissionAssignments < Service::BaseWithCurrentUser

  SUFFIXES = %w[_ids s].freeze
  MODELS = %w[Role Group].freeze

  def execute(user_data:)
    # Regular agents are not allowed to set Groups and Roles.
    MODELS.each do |model|
      SUFFIXES.each do |suffix|
        attribute = "#{model.downcase}#{suffix}"
        values    = user_data[attribute]
        user_data.delete(attribute) if !values.nil?
      end
    end

    # Check for create requests and set signup roles if no other roles are given.
    return true if user_data[:id].present? || user_data[:role_ids] || user_data[:roles]

    user_data[:role_ids] = Role.signup_role_ids
  end

end
