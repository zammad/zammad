# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class PostmasterFiltersController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some name",
  "type":"email",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note":"",
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2,
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/postmaster_filters.json

Response:
[
  {
    "id": 1,
    "name":"some name",
    ...
  },
  {
    "id": 2,
    "name":"some name",
    ...
  }
]

Test:
curl http://localhost/api/v1/postmaster_filters.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(PostmasterFilter, params)
  end

=begin

Resource:
GET /api/v1/postmaster_filters/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/postmaster_filters/#{id}.json -v -u #{login}:#{password}

=end

  def show
    model_show_render(PostmasterFilter, params)
  end

=begin

Resource:
POST /api/v1/postmaster_filters.json

Payload:
{
  "name":"some name",
  "type":"email",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note":"",
  "active":true,
}

Response:
{
  "id": 1,
  "name":"some name",
  "type":"email",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note": "",
  "active":true,
  ...
}

Test:
curl http://localhost/api/v1/postmaster_filters.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(PostmasterFilter, params)
  end

=begin

Resource:
PUT /api/v1/postmaster_filters/{id}.json

Payload:
{
  "name":"some name",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note":"",
  "active":true,
}

Response:
{
  "id": 1,
  "name":"some name",
  "match":{
    "From":"some@example.com"
  },
  "perform":{
    "x-zammad-ticket-priority":"3 high"
  },
  "note":"",
  "active":true,
  ...
}

Test:
curl http://localhost/api/v1/postmaster_filters.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(PostmasterFilter, params)
  end

=begin

Resource:

Response:

Test:

=end

  def destroy
    model_destroy_render(PostmasterFilter, params)
  end
end
