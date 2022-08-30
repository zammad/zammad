# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class User::CheckAttributesService < BaseService
  def execute(args)
    check(args[:user_data])
  end

  private

  def check(user_data)
    strip_attributes(user_data)

    # check for create requests and set signup roles if no other roles are given
    return true if user_data[:id].present?
    return true if user_data[:role_ids]
    return true if user_data[:roles]

    user_data[:role_ids] = Role.signup_role_ids
    true
  end

  def strip_attributes(user_data)
    # regular agents are not allowed to set Groups and Roles
    suffixes = %w[_ids s]
    %w[Role Group].each do |model|

      suffixes.each do |suffix|
        attribute = "#{model.downcase}#{suffix}"
        values    = user_data[attribute]

        next if values.nil?

        Rails.logger.warn "#{model} assignment is only allowed by admin! User with ID #{current_user.id} tried to assign #{values.inspect}"
        user_data.delete(attribute)
      end
    end

    true
  end
end
