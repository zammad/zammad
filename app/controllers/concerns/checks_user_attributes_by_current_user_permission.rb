module ChecksUserAttributesByCurrentUserPermission
  extend ActiveSupport::Concern

  private

  def check_attributes_by_current_user_permission(params)
    # admins can do whatever they want
    return true if current_user.permissions?('admin.user')

    # non-agents (customers) can't set anything
    raise Exceptions::NotAuthorized if !current_user.permissions?('ticket.agent')

    # regular agents are not allowed to set Groups and Roles
    %w[Role Group].each do |model|

      %w[_ids s].each do |suffix|
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
