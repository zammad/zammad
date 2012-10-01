class SignaturesController < ApplicationController
  before_filter :authentication_check

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some signature name",
  "body":"some signature body",
  "note":"some note",
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2,
  "created_by_id":2,
}
  
=end

=begin

Resource:
GET /api/signatures.json

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
curl http://localhost/api/signatures.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(Signature, params)
  end

=begin

Resource:
GET /api/signatures/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/signatures/#{id}.json -v -u #{login}:#{password}
 
=end

  def show
    model_show_render(Signature, params)
  end

=begin

Resource:
POST /api/signatures.json

Payload:
{
  "name": "some name",
  "note": "",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/signatures.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    model_create_render(Signature, params)
  end

=begin

Resource:
PUT /api/signatures/{id}.json

Payload:
{
  "name": "some name",
  "note": "",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/signatures.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    model_update_render(Signature, params)
  end

=begin

Resource:

Response:

Test:
 
=end

  def destroy
    model_destory_render(Signature, params)
  end
end
