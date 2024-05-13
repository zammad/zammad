# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class UserAccessTokenController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

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
    tokens      = Service::User::AccessToken::List.new(current_user).execute
    permissions = current_user.permissions_with_child_and_parent_elements

    render json: {
      tokens:      tokens,
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
    if params[:name].blank?
      raise Exceptions::UnprocessableEntity, __("The required parameter 'name' is missing.")
    end

    token = Service::User::AccessToken::Create
      .new(current_user, **params.permit(:name, :expires_at, permission: []).to_h.to_options)
      .execute

    render json: {
      token: token.token,
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
    raise Exceptions::UnprocessableEntity, __('The API token could not be found.') if !token

    token.destroy!
    render json: {}, status: :ok
  end

end
