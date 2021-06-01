# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class RolesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some role",
  "note":"some note",
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2,
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/roles.json

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
curl http://localhost/api/v1/roles.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(Role, params)
  end

=begin

Resource:
GET /api/v1/roles/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/roles/#{id}.json -v -u #{login}:#{password}

=end

  def show
    model_show_render(Role, params)
  end

=begin

Resource:
POST /api/v1/roles.json

Payload:
{
  "name": "some name",
  "note": "",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/roles.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(Role, params)
  end

=begin

Resource:
PUT /api/v1/roles/{id}.json

Payload:
{
  "name": "some name",
  "note": "",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/roles.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(Role, params)
  end

=begin

Resource:

Response:

Test:

=end

  def destroy
    model_destroy_render(Role, params)
  end
end
