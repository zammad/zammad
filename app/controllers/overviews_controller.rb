# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class OverviewsController < ApplicationController
  include CanPrioritize

  prepend_before_action { authentication_check && authorize! }

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some overview",
  "meta":{"m_a":1,"m_b":2},
  "condition":{"c_a":1,"c_b":2},
  "order":{"o_a":1,"o_b":2},
  "group_by":"group",
  "view":{"v_a":1,"v_b":2},
  "user_ids": null,
  "role_id": null,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2.
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/overviews

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
curl http://localhost/api/v1/overviews -v -u #{login}:#{password}

=end

  def index
    model_index_render(Overview, params)
  end

=begin

Resource:
GET /api/v1/overviews/#{id}

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/overviews/#{id} -v -u #{login}:#{password}

=end

  def show
    model_show_render(Overview, params)
  end

=begin

Resource:
POST /api/v1/overviews

Payload:
{
  "name":"some overview",
  "meta":{"m_a":1,"m_b":2},
  "condition":{"c_a":1,"c_b":2},
  "order":{"o_a":1,"o_b":2},
  "group_by":"group",
  "view":{"v_a":1,"v_b":2},
  "user_ids": null,
  "role_id": null,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/overviews -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(Overview, params)
  end

=begin

Resource:
PUT /api/v1/overviews/{id}

Payload:
{
  "name":"some overview",
  "meta":{"m_a":1,"m_b":2},
  "condition":{"c_a":1,"c_b":2},
  "order":{"o_a":1,"o_b":2},
  "group_by":"group",
  "view":{"v_a":1,"v_b":2},
  "user_ids": null,
  "role_id": null,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/overviews -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(Overview, params)
  end

=begin

Resource:
DELETE /api/v1/overviews/{id}

Response:
{}

Test:
curl http://localhost/api/v1/overviews/#{id} -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    model_destroy_render(Overview, params)
  end
end
