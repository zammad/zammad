# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class SlasController < ApplicationController
  before_filter :authentication_check

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some sla",
  "condition":{"c_a":1,"c_b":2},
  "data":{"o_a":1,"o_b":2},
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2.
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/slas.json

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
curl http://localhost/api/slas.json -v -u #{login}:#{password}

=end

  def index
    return if is_not_role('Admin')
    model_index_render(Sla, params)
  end

=begin

Resource:
GET /api/slas/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/slas/#{id}.json -v -u #{login}:#{password}

=end

  def show
    return if is_not_role('Admin')
    model_show_render(Sla, params)
  end

=begin

Resource:
POST /api/slas.json

Payload:
{
  "name":"some sla",
  "condition":{"c_a":1,"c_b":2},
  "data":{"o_a":1,"o_b":2},
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/slas.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    return if is_not_role('Admin')
    model_create_render(Sla, params)
  end

=begin

Resource:
PUT /api/slas/{id}.json

Payload:
{
  "name":"some sla",
  "condition":{"c_a":1,"c_b":2},
  "data":{"o_a":1,"o_b":2},
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/slas.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    return if is_not_role('Admin')
    model_update_render(Sla, params)
  end

=begin

Resource:
DELETE /api/slas/{id}.json

Response:
{}

Test:
curl http://localhost/api/slas.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    return if is_not_role('Admin')
    model_destory_render(Sla, params)
  end
end
