# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class UserAccessTokenController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

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
    tokens = Token.select(Token.column_names - %w[persistent name])
                  .where(action: 'api', persistent: true, user_id: current_user.id)
                  .order(updated_at: :desc, label: :asc)

    base_query       = Permission.order(:name).where(active: true)
    permission_names = current_user.permissions.pluck(:name)
    ancestor_names   = permission_names.flat_map { |name| Permission.with_parents(name) }.uniq -
                       permission_names
    descendant_names = permission_names.map { |name| "#{name}.%" }

    permissions = base_query.where(name: [*ancestor_names, *permission_names])

    descendant_names.each do |name|
      permissions = permissions.or(base_query.where('permissions.name LIKE ?', name))
    end

    permissions.select { |permission| permission.name.in?(ancestor_names) }
               .each { |permission| permission.preferences['disabled'] = true }

    render json: {
      tokens:      tokens.map(&:attributes),
      permissions: permissions.map(&:attributes),
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
