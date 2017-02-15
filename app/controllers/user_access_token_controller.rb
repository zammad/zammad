# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class UserAccessTokenController < ApplicationController
  prepend_before_action { authentication_check(permission: 'user_preferences.access_token') }

  def index
    tokens = Token.where(action: 'api', persistent: true, user_id: current_user.id).order('updated_at DESC, label ASC')
    token_list = []
    tokens.each { |token|
      attributes = token.attributes
      attributes.delete('persistent')
      attributes.delete('name')
      token_list.push attributes
    }
    local_permissions = current_user.permissions
    local_permissions_new = {}
    local_permissions.each { |key, _value|
      keys = Object.const_get('Permission').with_parents(key)
      keys.each { |local_key|
        next if local_permissions_new.key?([local_key])
        if local_permissions[local_key] == true
          local_permissions_new[local_key] = true
          next
        end
        local_permissions_new[local_key] = false
      }
    }
    permissions = []
    Permission.all.where(active: true).order(:name).each { |permission|
      next if !local_permissions_new.key?(permission.name) && !current_user.permissions?(permission.name)
      permission_attributes = permission.attributes
      if local_permissions_new[permission.name] == false
        permission_attributes['preferences']['disabled'] = true
      end
      permissions.push permission_attributes
    }

    render json: {
      tokens: token_list,
      permissions: permissions,
    }, status: :ok
  end

  def create
    if Setting.get('api_token_access') == false
      raise Exceptions::UnprocessableEntity, 'API token access disabled!'
    end
    if params[:label].empty?
      raise Exceptions::UnprocessableEntity, 'Need label!'
    end
    token = Token.create(
      action:      'api',
      label:       params[:label],
      persistent:  true,
      user_id:     current_user.id,
      expires_at:  params[:expires_at],
      preferences: {
        permission: params[:permission]
      }
    )
    render json: {
      name: token.name,
    }, status: :ok
  end

  def destroy
    token = Token.find_by(action: 'api', user_id: current_user.id, id: params[:id])
    raise Exceptions::UnprocessableEntity, 'Unable to find api token!' if !token
    token.destroy
    render json: {}, status: :ok
  end

end
