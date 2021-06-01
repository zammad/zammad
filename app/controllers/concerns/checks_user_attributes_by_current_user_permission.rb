# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ChecksUserAttributesByCurrentUserPermission
  extend ActiveSupport::Concern

  private

  def check_attributes_by_current_user_permission(params)
    authorize!

    # admins can do whatever they want
    return true if current_user.permissions?('admin.user')

    # regular agents are not allowed to set Groups and Roles
    suffixes = %w[_ids s]
    %w[Role Group].each do |model|

      suffixes.each do |suffix|
        attribute = "#{model.downcase}#{suffix}"
        values    = params[attribute]

        next if values.nil?

        logger.warn "#{model} assignment is only allowed by admin! User with ID #{current_user.id} tried to assign #{values.inspect}"
        params.delete(attribute)
      end
    end

    # check for create requests and set
    # signup roles if no other roles are given
    return true if params[:id].present?
    return true if params[:role_ids]
    return true if params[:roles]

    params[:role_ids] = Role.signup_role_ids
    true
  end
end
