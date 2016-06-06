# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class OrganizationsController < ApplicationController
  before_action :authentication_check

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"Znuny GmbH",
  "note":"",
  "active":true,
  "shared":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/organizations

Response:
[
  {
    "id": 1,
    "name": "some_name1",
    ...
  },
  {
    "id": 2,
    "name": "some_name2",
    ...
  }
]

Test:
curl http://localhost/api/v1/organizations -v -u #{login}:#{password}

=end

  def index
    offset = 0
    per_page = 1000

    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      per_page = params[:per_page].to_i
    end

    # only allow customer to fetch his own organization
    organizations = []
    if role?(Z_ROLENAME_CUSTOMER) && !role?(Z_ROLENAME_ADMIN) && !role?(Z_ROLENAME_AGENT)
      if current_user.organization_id
        organizations = Organization.where(id: current_user.organization_id).offset(offset).limit(per_page)
      end
    else
      organizations = Organization.all.offset(offset).limit(per_page)
    end

    if params[:full]
      assets = {}
      item_ids = []
      organizations.each {|item|
        item_ids.push item.id
        assets = item.assets(assets)
      }
      render json: {
        record_ids: item_ids,
        assets: assets,
      }, status: :ok
      return
    end

    render json: organizations
  end

=begin

Resource:
GET /api/v1/organizations/#{id}

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/organizations/#{id} -v -u #{login}:#{password}

=end

  def show

    # only allow customer to fetch his own organization
    if role?(Z_ROLENAME_CUSTOMER) && !role?(Z_ROLENAME_ADMIN) && !role?(Z_ROLENAME_AGENT)
      if !current_user.organization_id
        render json: {}
        return
      end
      if params[:id].to_i != current_user.organization_id
        response_access_deny
        return
      end
    end
    if params[:full]
      full = Organization.full( params[:id] )
      render json: full
      return
    end
    model_show_render(Organization, params)
  end

=begin

Resource:
POST /api/v1/organizations

Payload:
{
  "name": "some_name",
  "active": true,
  "note": "some note",
  "shared": true
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/organizations -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true,"shared": true,"note": "some note"}'

=end

  def create
    return if deny_if_not_role(Z_ROLENAME_AGENT)
    model_create_render(Organization, params)
  end

=begin

Resource:
PUT /api/v1/organizations/{id}

Payload:
{
  "id": 1
  "name": "some_name",
  "active": true,
  "note": "some note",
  "shared": true
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/organizations -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"id": 1,"name": "some_name","active": true,"shared": true,"note": "some note"}'

=end

  def update
    return if deny_if_not_role(Z_ROLENAME_AGENT)
    model_update_render(Organization, params)
  end

=begin

Resource:
DELETE /api/v1/organization/{id}

Response:
{}

Test:
curl http://localhost/api/v1/organization/{id} -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE -d '{}'

=end

  def destroy
    return if deny_if_not_role(Z_ROLENAME_AGENT)
    return if model_references_check(Organization, params)
    model_destory_render(Organization, params)
  end

  def search

    if role?(Z_ROLENAME_CUSTOMER) && !role?(Z_ROLENAME_ADMIN) && !role?(Z_ROLENAME_AGENT)
      response_access_deny
      return
    end

    # set limit for pagination if needed
    if params[:page] && params[:per_page]
      params[:limit] = params[:page].to_i * params[:per_page].to_i
    end

    query_params = {
      query: params[:term],
      limit: params[:limit],
      current_user: current_user,
    }
    if params[:role_ids] && !params[:role_ids].empty?
      query_params[:role_ids] = params[:role_ids]
    end

    # do query
    organization_all = Organization.search(query_params)

    # do pagination if needed
    if params[:page] && params[:per_page]
      offset = (params[:page].to_i - 1) * params[:per_page].to_i
      organization_all = organization_all.slice(offset, params[:per_page].to_i) || []
    end

    if params[:expand]
      render json: organization_all
      return
    end

    # build result list
    if !params[:full]
      organizations = []
      organization_all.each { |organization|
        a = { id: organization.id, label: organization.name }
        organizations.push a
      }

      # return result
      render json: organizations
      return
    end

    organization_ids = []
    assets = {}
    organization_all.each { |organization|
      assets = organization.assets(assets)
      organization_ids.push organization.id
    }

    # return result
    render json: {
      assets: assets,
      organization_ids: organization_ids.uniq,
    }
  end

  # GET /api/v1/organizations/history/1
  def history

    # permission check
    if !role?(Z_ROLENAME_ADMIN) && !role?(Z_ROLENAME_AGENT)
      response_access_deny
      return
    end

    # get organization data
    organization = Organization.find(params[:id])

    # get history of organization
    history = organization.history_get(true)

    # return result
    render json: history
  end

end
