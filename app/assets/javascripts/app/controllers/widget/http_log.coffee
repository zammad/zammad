class App.HttpLog extends App.Controller
  events:
    'click .js-record': 'show'

  constructor: ->
    super
    @fetch()
    @records = []

  fetch: =>
    @ajax(
      id:   'http_logs'
      type: 'GET'
      url:  "#{@apiPath}/http_logs/#{@facility}"
      data:
        limit: @limit || 50
      processData: true
      success: (data) =>
        if !@records[0] || (data[0] && @records[0] && data[0].updated_at isnt @records[0].updated_at)
          @records = data
          @render()
        @delay(@fetch, 20000)
    )

  render: =>
    @html App.view('widget/http_log')(
      records: @records
      description: @description
    )

  show: (e) =>
    e.preventDefault()
    record_id = $(e.currentTarget).data('id')
    for record in @records
      if record_id.toString() is record.id.toString()
        new Show(
          record: record
          container: @el.closest('.content')
        )
        return

class Show extends App.ControllerModal
  authenticateRequired: true
  large: true
  head: __('HTTP Log')
  buttonClose: true
  buttonCancel: false
  buttonSubmit: false

  constructor: ->
    super

  content: ->
    request_content  = App.Utils.text2html(JSON.stringify(@record.request.content, null, 2))
    response_content = App.Utils.text2html(JSON.stringify(@record.response.content, null, 2))

    # Special formatting for AI Provider + Webhook logs
    if @record?.facility and @record?.facility in ['AI::Provider', 'webhook']
      request_content  = @formatJsonData(@record.request.content)
      response_content = @formatJsonData(@record.response.content)

    App.view('widget/http_log_show')(
      record: @record
      request_content: request_content
      response_content: response_content
    )

  formatJsonData: (data) ->
    try
      [header, body] = data.split('\n\n')

      header = header?.replace(/\\n/g, '<br>')
      if !body
        return App.Utils.text2html(header).replace(/\\n/g, '<br>')

      body_json = JSON.parse(body)
      body_pretty = JSON.stringify(body_json, null, 2)
      return App.Utils.text2html(header + '\n\n' + body_pretty).replace(/\\n/g, '<br>')
    catch error
      App.Log.error 'App.HttpLog - Show', 'Invalid JSON value', error
      App.Utils.text2html(JSON.stringify(data))
