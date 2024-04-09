# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class OnlineNotificationsController < ApplicationController
  prepend_before_action -> { authorize! }, only: %i[show update destroy]
  prepend_before_action :authentication_check

=begin

Format:
JSON

Example:
{
  "id": 123,
  "o_id": 628,
  "object": "Ticket",
  "type": "escalation",
  "seen": true,
  "updated_at": "2016-08-16T07:55:42.119Z",
  "created_at": "2016-08-16T07:55:42.119Z"
}

=end

=begin

Resource:
GET /api/v1/online_notifications

Response:
[
  {
    "id": 1,
    "object": "Ticket",
    "type": "escalation",
    "seen": true,
    ...
  },
  {
    "id": 2,
    "object": "Ticket",
    "type": "escalation",
    "seen": false,
    ...
  }
]

Test:
curl http://localhost/api/v1/online_notifications -v -u #{login}:#{password}

=end

  def index
    online_notifications = OnlineNotification.list(current_user)

    if response_expand?
      list = online_notifications.map(&:attributes_with_association_names)
      render json: list, status: :ok
      return
    end

    if response_full?
      assets = {}
      item_ids = []
      online_notifications.each do |item|
        item_ids.push item['id']
        assets = item.assets(assets)
      end
      render json: {
        record_ids: item_ids,
        assets:     assets,
      }, status: :ok
      return
    end

    all = online_notifications.map(&:attributes_with_association_ids)
    render json: all, status: :ok
  end

=begin

Resource:
GET /api/v1/online_notifications/#{id}

Response:
{
  "id": 123,
  "o_id": 628,
  "object": "Ticket",
  "type": "escalation",
  "seen": true,
  "updated_at": "2016-08-16T07:55:42.119Z",
  "created_at": "2016-08-16T07:55:42.119Z"
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
  "id": 123,
  "o_id": 628,
  "object": "Ticket",
  "type": "escalation",
  "seen": true,
  "updated_at": "2016-08-16T07:55:42.119Z",
  "created_at": "2016-08-16T07:55:42.119Z"
}

Response:
{
  "id": 123,
  "o_id": 628,
  "object": "Ticket",
  "type": "escalation",
  "seen": true,
  "updated_at": "2016-08-16T07:55:42.119Z",
  "created_at": "2016-08-16T07:55:42.119Z"
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
    OnlineNotification
      .list(current_user, limit: nil, access: 'ignore')
      .where(seen: false)
      .in_batches
      .each_record do |notification|
        notification.update!(seen: true)
      end

    render json: {}, status: :ok
  end
end
