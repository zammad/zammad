# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class MacrosController < ApplicationController
  prepend_before_action :authentication_check

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some text_module",
  "perform":{
    "ticket.priority_id": 5,
    "ticket.state_id": 2,
  },
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2,
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/macros.json

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
curl http://localhost/api/v1/macros.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(Macro, params)
  end

=begin

Resource:
GET /api/v1/macros/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/macros/#{id}.json -v -u #{login}:#{password}

=end

  def show
    model_show_render(Macro, params)
  end

=begin

Resource:
POST /api/v1/macros.json

Payload:
{
  "name": "some name",
  "perform":{
    "ticket.priority_id": 5,
    "ticket.state_id": 2,
  },
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/macros.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(Macro, params)
  end

=begin

Resource:
PUT /api/v1/macros/{id}.json

Payload:
{
  "name": "some name",
  "perform":{
    "ticket.priority_id": 5,
    "ticket.state_id": 2,
  },
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/macros.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(Macro, params)
  end

=begin

Resource:
DELETE /api/v1/macros/{id}.json

Response:
{}

Test:
curl http://localhost/api/v1/macros.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    model_destroy_render(Macro, params)
  end
end
