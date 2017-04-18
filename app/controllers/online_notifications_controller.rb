# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class OnlineNotificationsController < ApplicationController
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
    if params[:full]
      render json: OnlineNotification.list_full(current_user, 100)
      return
    end

    notifications = OnlineNotification.list(current_user, 100)
    model_index_render_result(notifications)
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
    return if !access?
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
    return if !access?
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
    return if !access?
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
    notifications = OnlineNotification.list(current_user, 100)
    notifications.each do |notification|
      if !notification['seen']
        OnlineNotification.seen( id: notification['id'] )
      end
    end
    render json: {}, status: :ok
  end

  private

  def access?
    notification = OnlineNotification.find(params[:id])
    if notification.user_id != current_user.id
      response_access_deny
      return false
    end
    true
  end

end
