# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class SlasController < ApplicationController
  before_action :authentication_check

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
    return if deny_if_not_role(Z_ROLENAME_ADMIN)

    assets = {}

    # calendars
    calendar_ids = []
    Calendar.all.order(:name, :created_at).each {|calendar|
      calendar_ids.push calendar.id
      assets = calendar.assets(assets)
    }

    # slas
    sla_ids = []
    models = Models.all
    Sla.all.order(:name, :created_at).each {|sla|
      sla_ids.push sla.id
      assets = sla.assets(assets)

      # get assets of condition
      sla.condition.each {|item, content|
        attribute = item.split(/\./)
        next if !attribute[1]
        attribute_class = attribute[0].to_classname.constantize
        reflection = attribute[1].sub(/_id$/, '')
        reflection = reflection.to_sym
        next if !models[attribute_class]
        next if !models[attribute_class][:reflections]
        next if !models[attribute_class][:reflections][reflection]
        next if !models[attribute_class][:reflections][reflection].klass
        attribute_ref_class = models[attribute_class][:reflections][reflection].klass
        if content['value'].class == Array
          content['value'].each {|item_id|
            attribute_object = attribute_ref_class.find_by(id: item_id)
            assets = attribute_object.assets(assets)
          }
        else
          attribute_object = attribute_ref_class.find_by(id: content['value'])
          assets = attribute_object.assets(assets)
        end
      }
    }

    render json: {
      calendar_ids: calendar_ids,
      sla_ids: sla_ids,
      assets: assets,
    }, status: :ok
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
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
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
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
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
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
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
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Sla, params)
  end
end
