# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class OnlineNotificationsController < ApplicationController
  prepend_before_action -> { authorize! }, only: %i[show update destroy]
  prepend_before_action :authentication_check

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
curl http://localhost/api/v1/online_notifications.json -v -u #{login}:#{password}

=end

  def index
    online_notifications = OnlineNotification.list(current_user, 200)

    if response_expand?
      list = []
      online_notifications.each do |item|
        list.push item.attributes_with_association_names
      end
      render json: list, status: :ok
      return
    end

    if response_full?
      assets = {}
      item_ids = []
      online_notifications.each do |item|
        item_ids.push item.id
        assets = item.assets(assets)
      end
      render json: {
        record_ids: item_ids,
        assets:     assets,
      }, status: :ok
      return
    end

    all = []
    online_notifications.each do |item|
      all.push item.attributes_with_association_ids
    end
    render json: all, status: :ok
  end

=begin

Resource:
GET /api/v1/online_notifications/{id}

Payload:
{
  "id": "123",
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/online_notifications/#{id} -v -u #{login}:#{password}

=end

  def show
    model_show_render(OnlineNotification, params)
  end

=begin

Resource:
PUT /api/v1/online_notifications/{id}

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
curl http://localhost/api/v1/online_notifications -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(OnlineNotification, params)
  end

=begin

Resource:
DELETE /api/v1/online_notifications/{id}.json

Response:
{}

Test:
curl http://localhost/api/v1/online_notifications/{id}.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    model_destroy_render(OnlineNotification, params)
  end

=begin

Resource:
PUT /api/v1/online_notifications/mark_all_as_read

Payload:
{}

Response:
{}

Test:
curl http://localhost/api/v1/online_notifications/mark_all_as_read -v -u #{login}:#{password} -X POST -d '{}'

=end

  def mark_all_as_read
    notifications = OnlineNotification.list(current_user, 200)
    notifications.each do |notification|
      next if notification['seen']

      OnlineNotification.find(notification['id']).update!(seen: true)
    end
    render json: {}, status: :ok
  end
end
