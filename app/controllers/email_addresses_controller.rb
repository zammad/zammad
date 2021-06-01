# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class EmailAddressesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

=begin

Format:
JSON

Example:
{
  "id":1,
  "realname":"some realname",
  "email":"system@example.com",
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2,
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/email_addresses.json

Response:
[
  {
    "id": 1,
    "realname":"some realname1",
    ...
  },
  {
    "id": 2,
    "realname":"some realname2",
    ...
  }
]

Test:
curl http://localhost/api/v1/email_addresses.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(EmailAddress, params)
  end

=begin

Resource:
GET /api/v1/email_addresses/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/email_addresses/#{id}.json -v -u #{login}:#{password}

=end

  def show
    model_show_render(EmailAddress, params)
  end

=begin

Resource:
POST /api/v1/email_addresses.json

Payload:
{
  "realname":"some realname",
  "email":"system@example.com",
  "note": "",
  "active":true,
}

Response:
{
  "id": 1,
  "realname":"some realname",
  "email":"system@example.com",
  ...
}

Test:
curl http://localhost/api/v1/email_addresses.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(EmailAddress, params)
  end

=begin

Resource:
PUT /api/v1/email_addresses/{id}.json

Payload:
{
  "realname":"some realname",
  "email":"system@example.com",
  "note": "",
  "active":true,
}

Response:
{
  "id": 1,
  "realname":"some realname",
  "email":"system@example.com",
  ...
}

Test:
curl http://localhost/api/v1/email_addresses/#{id}.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(EmailAddress, params)
  end

=begin

Resource:
POST /api/v1/email_addresses/{id}.json

Response:
{}

Test:
curl http://localhost/api/v1/email_addresses/#{id}.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    model_destroy_render(EmailAddress, params)
  end
end
