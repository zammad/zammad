# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class UserAccessTokenController < ApplicationController
  prepend_before_action { authentication_check(permission: 'user_preferences.access_token') }

=begin

Resource:
GET /api/v1/user_access_token

Response:
{
  "tokens":[
    {"id":1,"label":"some user access token","preferences":{"permission":["cti.agent","ticket.agent"]},"last_used_at":null,"expires_at":null,"created_at":"2018-07-11T08:18:56.947Z"}
    {"id":2,"label":"some user access token 2","preferences":{"permission":[ticket.agent"]},"last_used_at":null,"expires_at":null,"created_at":"2018-07-11T08:18:56.947Z"}
  ],
  "permissions":[
    {id: 1, name: "admin", note: "Admin Interface", preferences: {}, active: true,...},
    {id: 2, name: "admin.user", note: "Manage Users", preferences: {}, active: true,...},
    ...
  ]
}

Test:
curl http://localhost/api/v1/user_access_token -v -u #{login}:#{password}

=end

  def index
    tokens = Token.where(action: 'api', persistent: true, user_id: current_user.id).order(updated_at: :desc, label: :asc)
    token_list = []
    tokens.each do |token|
      attributes = token.attributes
      attributes.delete('persistent')
      attributes.delete('name')
      token_list.push attributes
    end
    local_permissions = current_user.permissions
    local_permissions_new = {}
    local_permissions.each_key do |key|
      keys = ::Permission.with_parents(key)
      keys.each do |local_key|
        next if local_permissions_new.key?([local_key])

        if local_permissions[local_key] == true
          local_permissions_new[local_key] = true
          next
        end
        local_permissions_new[local_key] = false
      end
    end
    permissions = []
    Permission.all.where(active: true).order(:name).each do |permission|
      next if !local_permissions_new.key?(permission.name) && !current_user.permissions?(permission.name)

      permission_attributes = permission.attributes
      if local_permissions_new[permission.name] == false
        permission_attributes['preferences']['disabled'] = true
      end
      permissions.push permission_attributes
    end

    render json: {
      tokens:      token_list,
      permissions: permissions,
    }, status: :ok
  end

=begin

Resource:
POST /api/v1/user_access_token

Payload:
{
  "label":"some test",
  "permission":["cti.agent","ticket.agent"],
  "expires_at":null
}

Response:
{
  "name":"new_token_only_shown_once"
}

Test:
curl http://localhost/api/v1/user_access_token -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"label":"some test","permission":["cti.agent","ticket.agent"],"expires_at":null}'

=end

  def create
    if Setting.get('api_token_access') == false
      raise Exceptions::UnprocessableEntity, 'API token access disabled!'
    end
    if params[:label].blank?
      raise Exceptions::UnprocessableEntity, 'Need label!'
    end

    token = Token.create!(
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

=begin

Resource:
DELETE /api/v1/user_access_token/{id}

Response:
{}

Test:
curl http://localhost/api/v1/user_access_token/{id} -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    token = Token.find_by(action: 'api', user_id: current_user.id, id: params[:id])
    raise Exceptions::UnprocessableEntity, 'Unable to find api token!' if !token

    token.destroy!
    render json: {}, status: :ok
  end

end
