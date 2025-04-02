# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class GroupsController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some group",
  "assignment_timeout": null,
  "follow_up_assignment": true,
  "follow_up_possible": "yes",
  "note":"",
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/groups

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
curl http://localhost/api/v1/groups -v -u #{login}:#{password}

=end

  def index
    model_index_render(GroupPolicy::Scope.new(UserInfo.current_user, Group).resolve.sorted, params)
  end

=begin

Resource:
GET /api/v1/groups/#{id}

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/groups/#{id} -v -u #{login}:#{password}

=end

  def show
    model_show_render(GroupPolicy::Scope.new(UserInfo.current_user, Group).resolve, params)
  end

=begin

Resource:
POST /api/v1/groups

Payload:
{
  "name": "some name",
  "assignment_timeout": null,
  "follow_up_assignment": true,
  "follow_up_possible": "yes",
  "note":"",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/groups -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(Group, params)
  end

=begin

Resource:
PUT /api/v1/groups/{id}

Payload:
{
  "name": "some name",
  "assignment_timeout": null,
  "follow_up_assignment": true,
  "follow_up_possible": "yes",
  "note":"",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/groups -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(Group, params)
  end

  def search
    model_search_render(Group, params)
  end

=begin

Resource:
DELETE /api/v1/groups/{id}

Response:
{}

Test:
curl http://localhost/api/v1/groups/{id} -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE -d '{}'

=end

  def destroy
    model_references_check(Group, params)
    model_destroy_render(Group, params)
  end
end
