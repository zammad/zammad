# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TemplatesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some template",
  "user_id": null,
  "options":{"a":1,"b":2},
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2.
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/templates.json

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
curl http://localhost/api/v1/templates.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(Template, params)
  end

=begin

Resource:
GET /api/v1/templates/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/templates/#{id}.json -v -u #{login}:#{password}

=end

  def show
    model_show_render(Template, params)
  end

=begin

Resource:
POST /api/v1/templates.json

Payload:
{
  "name": "some name",
  "options":{"a":1,"b":2},
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/templates.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(Template, params)
  end

=begin

Resource:
PUT /api/v1/templates/{id}.json

Payload:
{
  "name": "some name",
  "options":{"a":1,"b":2},
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/templates.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(Template, params)
  end

=begin

Resource:
DELETE /api/v1/templates/{id}.json

Response:
{}

Test:
curl http://localhost/api/v1/templates.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    model_destroy_render(Template, params)
  end
end
