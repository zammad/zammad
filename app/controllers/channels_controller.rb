# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class ChannelsController < ApplicationController
  before_action :authentication_check

=begin

Format:
JSON

Example:
{
  "id":1,
  "area":"Email::Inbound",
  "adapter":"IMAP",
  "group_id:": 1,
  "options":{
    "host":"mail.example.com",
    "user":"some_user",
    "password":"some_password",
    "ssl":true
  },
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2.
  "created_by_id":2,
}

{
  "id":1,
  "area":"Twitter::Inbound",
  "adapter":"Twitter",
  "group_id:": 1,
  "options":{
    "auth": {
      "consumer_key":"PJ4c3dYYRtSZZZdOKo8ow",
      "consumer_secret":"ggAdnJE2Al1Vv0cwwvX5bdvKOieFs0vjCIh5M8Dxk",
      "oauth_token":"293437546-xxRa9g74CercnU5AvY1uQwLLGIYrV1ezYtpX8oKW",
      "oauth_token_secret":"ju0E4l9OdY2Lh1iTKMymAu6XVfOaU2oGxmcbIMRZQK4",
    },
    "sync":{
      "search":[
        {
          "item":"#otrs",
          "type": "mixed", # optional, possible 'mixed' (default), 'recent', 'popular'
          "group_id:": 1,
          "limit": 1, # optional
        },
        {
          "item":"#zombie23",
          "group_id:": 2,
        },
        {
          "item":"#otterhub",
          "group_id:": 3,
        }
      ],
      "mentions" {
        "group_id:": 4,
        "limit": 100, # optional
      },
      "direct_messages": {
        "group_id:": 4,
        "limit": 1, # optional
      }
    }
  },
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2.
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/channels.json

Response:
[
  {
    "id": 1,
    "area":"Email::Inbound",
    "adapter":"IMAP",
    ...
  },
  {
    "id": 2,
    "area":"Email::Inbound",
    "adapter":"IMAP",
    ...
  }
]

Test:
curl http://localhost/api/v1/channels.json -v -u #{login}:#{password}

=end

  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(Channel, params)
  end

=begin

Resource:
GET /api/v1/channels/#{id}.json

Response:
{
  "id": 1,
  "area":"Email::Inbound",
  "adapter":"IMAP",
  ...
}

Test:
curl http://localhost/api/v1/channels/#{id}.json -v -u #{login}:#{password}

=end

  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(Channel, params)
  end

=begin

Resource:
POST /api/v1/channels.json

Payload:
{
  "area":"Email::Inbound",
  "adapter":"IMAP",
  "group_id:": 1,
  "options":{
    "host":"mail.example.com",
    "user":"some_user",
    "password":"some_password",
    "ssl":true
  },
  "active":true,
}

Response:
{
  "area":"Email::Inbound",
  "adapter":"IMAP",
  ...
}

Test:
curl http://localhost/api/v1/channels.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Channel, params)
  end

=begin

Resource:
PUT /api/v1/channels/{id}.json

Payload:
{
  "id":1,
  "area":"Email::Inbound",
  "adapter":"IMAP",
  "group_id:": 1,
  "options":{
    "host":"mail.example.com",
    "user":"some_user",
    "password":"some_password",
    "ssl":true
  },
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/channels.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Channel, params)
  end

=begin

Resource:
DELETE /api/v1/channels/{id}.json

Response:
{}

Test:
curl http://localhost/api/v1/channels.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Channel, params)
  end
end
