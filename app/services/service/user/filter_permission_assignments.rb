# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::FilterPermissionAssignments < Service::Base

  SUFFIXES = %w[_ids s].freeze
  MODELS = %w[Role Group].freeze

  requires_current_user!

  attr_reader :user_data

  def initialize(user_data:)
    @user_data = user_data
  end

  def execute
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
