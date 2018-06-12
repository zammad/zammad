# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TextModulesController < ApplicationController
  prepend_before_action :authentication_check

=begin

Format:
JSON

Example:
{
  "id":1,
  "name":"some text_module",
  "user_id": null,
  "keywords":"some keywords",
  "content":"some content",
  "active":true,
  "updated_at":"2012-09-14T17:51:53Z",
  "created_at":"2012-09-14T17:51:53Z",
  "updated_by_id":2.
  "created_by_id":2,
}

=end

=begin

Resource:
GET /api/v1/text_modules.json

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
curl http://localhost/api/v1/text_modules.json -v -u #{login}:#{password}

=end

  def index
    permission_check('ticket.agent')
    model_index_render(TextModule, params)
  end

=begin

Resource:
GET /api/v1/text_modules/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/text_modules/#{id}.json -v -u #{login}:#{password}

=end

  def show
    permission_check('ticket.agent')
    model_show_render(TextModule, params)
  end

=begin

Resource:
POST /api/v1/text_modules.json

Payload:
{
  "name": "some name",
  "keywords":"some keywords",
  "content":"some content",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/text_modules.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def create
    permission_check('admin.text_module')
    model_create_render(TextModule, params)
  end

=begin

Resource:
PUT /api/v1/text_modules/{id}.json

Payload:
{
  "name": "some name",
  "keywords":"some keywords",
  "content":"some content",
  "active":true,
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/text_modules.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name","active": true, "note": "some note"}'

=end

  def update
    permission_check('admin.text_module')
    model_update_render(TextModule, params)
  end

=begin

Resource:
DELETE /api/v1/text_modules/{id}.json

Response:
{}

Test:
curl http://localhost/api/v1/text_modules.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    permission_check('admin.text_module')
    model_destroy_render(TextModule, params)
  end

  # @path    [GET] /text_modules/import_example
  #
  # @summary          Download of example CSV file.
  # @notes            The requester have 'admin.text_module' permissions to be able to download it.
  # @example          curl -u 'me@example.com:test' http://localhost:3000/api/v1/text_modules/import_example
  #
  # @response_message 200 File download.
  # @response_message 401 Invalid session.
  def import_example
    permission_check('admin.text_module')
    csv_string = TextModule.csv_example(
      col_sep: params[:col_sep] || ',',
    )
    send_data(
      csv_string,
      filename: 'text_module-example.csv',
      type: 'text/csv',
      disposition: 'attachment'
    )

  end

  # @path    [POST] /text_modules/import
  #
  # @summary          Starts import.
  # @notes            The requester have 'admin.text_module' permissions to be create a new import.
  # @example          curl -u 'me@example.com:test' -F 'file=@/path/to/file/Textbausteine_final2.csv' 'https://your.zammad/api/v1/text_modules/import?try=true'
  # @example          curl -u 'me@example.com:test' -F 'file=@/path/to/file/Textbausteine_final2.csv' 'https://your.zammad/api/v1/text_modules/import'
  #
  # @response_message 201 Import started.
  # @response_message 401 Invalid session.
  def import_start
    permission_check('admin.text_module')
    string = params[:data] || params[:file].read.force_encoding('utf-8')
    result = TextModule.csv_import(
      string: string,
      parse_params: {
        col_sep: params[:col_sep] || ',',
      },
      try: params[:try],
      delete: params[:delete],
    )
    render json: result, status: :ok
  end

end
