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
GET /api/organizations.json

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
curl http://localhost/api/organizations.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(Organization, params)
  end

=begin

Resource:
GET /api/organizations/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/organizations/#{id}.json -v -u #{login}:#{password}
 
=end

  def show
    model_show_render(Organization, params)
  end

=begin

Resource:
POST /api/organizations.json

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
curl http://localhost/api/organizations.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true,"shared": true,"note": "some note"}'

=end

  def create
    model_create_render(Organization, params)
  end

=begin

Resource:
PUT /api/organizations/{id}.json

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
curl http://localhost/api/organizations.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"id": 1,"name": "some_name","active": true,"shared": true,"note": "some note"}'

=end

  def update
    model_update_render(Organization, params)
  end

=begin

Resource:

Response:

Test:
 
=end

def destroy
    model_destory_render(Organization, params)
  end
end
