class App.HttpLog extends App.Controller
  events:
    'click .js-record': 'show'

  constructor: ->
    super
    @fetch()
    @records = []

  fetch: =>
    @ajax(
      id:    'http_logs'
      type:  'GET'
      url:   "#{@apiPath}/http_logs/#{@facility}"
      data:
        limit: @limit || 50
      processData: true
      success: (data) =>
        @records = data
        @render()
    )

  render: =>
    @html App.view('widget/http_log')(
      records: @records
    )
    #@delay(message, 2000)

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
  head: 'HTTP Log'
  buttonClose: true
  buttonCancel: false
  buttonSubmit: false

  constructor: ->
    super

  content: ->
    console.log('cont')
    App.view('widget/http_log_show')(
      record: @record
    )
