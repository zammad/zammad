module ChecksUserAttributesByCurrentUserPermission
  extend ActiveSupport::Concern

  private

  def check_attributes_by_current_user_permission(params)
    return true if current_user.permissions?('admin.user')

    %i[role_ids roles].each do |key|
      next if !params[key]
      if current_user.permissions?('ticket.agent')
        params.delete(key)
      else
        logger.info "Role assignment is only allowed by admin! current_user_id: #{current_user.id} assigned to #{params[key].inspect}"
        raise Exceptions::NotAuthorized, 'This role assignment is only allowed by admin!'
      end
    end
    if current_user.permissions?('ticket.agent') && !params[:role_ids] && !params[:roles] && params[:id].blank?
      params[:role_ids] = Role.signup_role_ids
    end

    %i[group_ids groups].each do |key|
      next if !params[key]
      if current_user.permissions?('ticket.agent')
        params.delete(key)
      else
        logger.info "Group relation assignment is only allowed by admin! current_user_id: #{current_user.id} assigned to #{params[key].inspect}"
        raise Exceptions::NotAuthorized, 'Group relation is only allowed by admin!'
      end
    end

    return true if current_user.permissions?('ticket.agent')

    response_access_deny
    false
  end

end
