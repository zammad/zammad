# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TemplatesController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

=begin

Format:
JSON

Example:
{
  "id": 1,
  "name": "some template",
  "user_id": null,
  "options": {
    "ticket.title": {
      "value": "some title"
    },
    "ticket.customer_id": {
      "value": "2",
      "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
    }
  },
  "updated_at": "2012-09-14T17:51:53Z",
  "created_at": "2012-09-14T17:51:53Z",
  "updated_by_id": 2,
  "created_by_id": 2
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
    model_index_render(policy_scope(Template), params)
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
    model_show_render(policy_scope(Template), params)
  end

=begin

Resource:
POST /api/v1/templates.json

Payload:
{
  "name": "some name",
  "options": {
    "ticket.title": {
      "value": "some title"
    },
    "ticket.customer_id": {
      "value": "2",
      "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
    }
  }
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/templates.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name", "options": {"ticket.title": {"value": "some title"},"ticket.customer_id": {"value": "2", "value_completion": "Nicole Braun <nicole.braun@zammad.org>"}}}'

=end

  def create
    model_create_render(policy_scope(Template), params)
  end

=begin

Resource:
PUT /api/v1/templates/{id}.json

Payload:
{
  "name": "some name",
  "options": {
    "ticket.title": {
      "value": "some title"
    },
    "ticket.customer_id": {
      "value": "2",
      "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
    }
  }
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/templates/1.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name", "options": {"ticket.title": {"value": "some title"},"ticket.customer_id": {"value": "2", "value_completion": "Nicole Braun <nicole.braun@zammad.org>"}}}'

=end

  def update
    model_update_render(policy_scope(Template), params)
  end

  def search
    model_search_render(Template, params)
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
    model_destroy_render(policy_scope(Template), params)
  end
end
