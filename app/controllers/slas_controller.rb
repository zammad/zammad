# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class SlasController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

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
GET /api/v1/slas.json

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
curl http://localhost/api/v1/slas.json -v -u #{login}:#{password}

=end

  def index

    if response_full?

      # calendars
      assets = {}
      Calendar.all.each do |calendar|
        assets = calendar.assets(assets)
      end

      # slas
      sla_ids = []
      Sla.all.each do |item|
        sla_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids: sla_ids,
        assets:     assets,
      }, status: :ok
      return
    end

    model_index_render(Sla, params)
  end

=begin

Resource:
GET /api/v1/slas/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/slas/#{id}.json -v -u #{login}:#{password}

=end

  def show
    model_show_render(Sla, params)
  end

=begin

Resource:
POST /api/v1/slas.json

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
curl http://localhost/api/v1/slas.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(Sla, params)
  end

=begin

Resource:
PUT /api/v1/slas/{id}.json

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
curl http://localhost/api/v1/slas.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(Sla, params)
  end

=begin

Resource:
DELETE /api/v1/slas/{id}.json

Response:
{}

Test:
curl http://localhost/api/v1/slas.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    model_destroy_render(Sla, params)
  end

end
