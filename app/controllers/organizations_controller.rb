# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class OrganizationsController < ApplicationController
  before_filter :authentication_check

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
GET /api/v1/organizations.json

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
curl http://localhost/api/v1/organizations.json -v -u #{login}:#{password}

=end

  def index

    # only allow customer to fetch his own organization
    organizations = []
    if is_role('Customer') && !is_role('Admin') && !is_role('Agent')
      if current_user.organization_id
        organizations = Organization.where( :id => current_user.organization_id )
      end
    else
      organizations = Organization.all
    end
    render :json => organizations
  end

=begin

Resource:
GET /api/v1/organizations/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/organizations/#{id}.json -v -u #{login}:#{password}

=end

  def show

    # only allow customer to fetch his own organization
    if is_role('Customer') && !is_role('Admin') && !is_role('Agent')
      if !current_user.organization_id
        render :json => {}
        return
      end
      if params[:id].to_i != current_user.organization_id
        response_access_deny
        return
      end
    end
    model_show_render(Organization, params)
  end

=begin

Resource:
POST /api/v1/organizations.json

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
curl http://localhost/api/v1/organizations.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true,"shared": true,"note": "some note"}'

=end

  def create
    return if deny_if_not_role('Agent')
    model_create_render(Organization, params)
  end

=begin

Resource:
PUT /api/v1/organizations/{id}.json

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
curl http://localhost/api/v1/organizations.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"id": 1,"name": "some_name","active": true,"shared": true,"note": "some note"}'

=end

  def update
    return if deny_if_not_role('Agent')
    model_update_render(Organization, params)
  end

=begin

Resource:

Response:

Test:

=end

  def destroy
    return if deny_if_not_role('Agent')
    model_destory_render(Organization, params)
  end
end
