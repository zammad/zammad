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
  head: 'HTTP Log'
  buttonClose: true
  buttonCancel: false
  buttonSubmit: false

  constructor: ->
    super

  content: ->
    App.view('widget/http_log_show')(
      record: @record
    )
