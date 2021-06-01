# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class ReportProfilesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some report_profile",
  "condition":{"c_a":1,"c_b":2},
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2.
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/report_profiles.json

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
curl http://localhost/api/report_profiles.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(Report::Profile, params)
  end

=begin

Resource:
GET /api/report_profiles/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/report_profiles/#{id}.json -v -u #{login}:#{password}

=end

  def show
    model_show_render(Report::Profile, params)
  end

=begin

Resource:
POST /api/report_profiles.json

Payload:
{
  "name":"some report_profile",
  "condition":{"c_a":1,"c_b":2},
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/report_profiles.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(Report::Profile, params)
  end

=begin

Resource:
PUT /api/report_profiles/{id}.json

Payload:
{
  "name":"some report_profile",
  "condition":{"c_a":1,"c_b":2},
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/report_profiles.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(Report::Profile, params)
  end

=begin

Resource:
DELETE /api/report_profiles/{id}.json

Response:
{}

Test:
curl http://localhost/api/report_profiles.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    model_destroy_render(Report::Profile, params)
  end

end
